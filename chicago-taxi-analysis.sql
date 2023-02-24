--- Count of Trips per Year
WITH trips AS(
  SELECT
  EXTRACT(YEAR FROM trip_start_timestamp) year,
  COUNT(*) all_trips
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  GROUP BY 1
)

SELECT
  year,
  all_trips,
    -- Calculating difference in trips from previous year 
    -- to analyze impact of COVID lockdown in 2020
  all_trips - LAG(all_trips) OVER(ORDER BY year) as year_to_year_difference 
FROM trips
GROUP BY 1,2
ORDER BY 1;

--- Average Trip Miles on Daily Hour
SELECT
  EXTRACT(HOUR FROM trip_start_timestamp) hour,
  ROUND(AVG(trip_miles), 2) avg_miles
FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
GROUP BY 1
ORDER BY 1;

--- Average Speed per Weekday and Daily Hour
WITH weekdays AS(
SELECT ['Sun', 'Mon', 'Tues', 'Wed', 'Thurs', 'Fri', 'Sat'] AS daysofweek)

SELECT
  daysofweek[ORDINAL(EXTRACT(DAYOFWEEK FROM trip_start_timestamp))] weekday,
  EXTRACT(HOUR FROM trip_start_timestamp) hour,
  ROUND(AVG(trip_miles / TIMESTAMP_DIFF(trip_end_timestamp,
    trip_start_timestamp,
    SECOND))* 3600, 1) speed,
FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`, weekdays
WHERE trip_miles > 0
  AND trip_end_timestamp > trip_start_timestamp
GROUP BY 1, 2
ORDER BY 1, 2;

--- Taxi Company with Most Trips Divided into Quartiles
SELECT
  company,
  COUNT(*) taxi_trips,
  NTILE(4) OVER(ORDER BY COUNT(*) DESC) quartile
FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
WHERE fare IS NOT NULL
  AND company IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC;

--- Saving Result as Temp Table
CREATE TABLE `chicago_taxi.chicago-company-trips`
OPTIONS(expiration_timestamp=TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL 3 DAY)
) AS
SELECT
  company,
  COUNT(*) taxi_trips,
  NTILE(4) OVER(ORDER BY COUNT(*) DESC) quartile
FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
WHERE fare IS NOT NULL
  AND company IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC;

SELECT
  quartile,
  ROUND(AVG(taxi_trips), 2) avg_trips
FROM chicago_taxi.chicago-company-trips
GROUP BY 1;

--- Sum of rips, Fare, and Revenue per Company in 2022
SELECT
  company,
  ROUND(SUM(trip_total), 2) total_revenue,
  ROUND(SUM(trip_miles) / 25 * 3.08, 2) cost_of_trip,
    -- Assuming Average 25 MPG of taxi cabs and Average cost of Gasoline to 3.10 
  ROUND(SUM(trip_total) - SUM(trip_miles) / 25 * 3.10, 2) profit
FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
WHERE company IS NOT NULL
  AND EXTRACT(YEAR FROM trip_start_timestamp) = 2022
GROUP BY 1
ORDER BY 4 DESC;

--- Average Trip Cost, Tips, Duration per Weekday and Hour for 2022
WITH weekdays AS(
SELECT ['Sun', 'Mon', 'Tues', 'Wed', 'Thurs', 'Fri', 'Sat'] AS daysofweek)

SELECT
  ROUND(AVG(trip_total), 2) trip_total_cost,
  ROUND(AVG(tips), 2) avg_tips,
  CONCAT(ROUND(AVG(trip_seconds) / 60, 2), ' hrs') trip_duration,
  daysofweek[ORDINAL(EXTRACT(DAYOFWEEK FROM trip_start_timestamp))] weekday,
  EXTRACT(HOUR FROM trip_start_timestamp) hour
FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`, weekdays
WHERE trip_seconds > 0
  AND fare > 0
  AND EXTRACT(YEAR FROM trip_start_timestamp) = 2022
GROUP BY 4, 5
ORDER BY 4, 5;

--- Using Previous Query as Training Data but Expanding Date Range to 2020 - 2022
CREATE OR REPLACE MODEL chicago_taxi.taxi_fare_model
OPTIONS
(model_type='linear_reg', labels=['trip_total_cost']) AS
WITH weekdays AS(
SELECT ['Sun', 'Mon', 'Tues', 'Wed', 'Thurs', 'Fri', 'Sat'] AS daysofweek)

SELECT
  trip_total trip_total_cost,
  tips,
  CONCAT(ROUND(trip_seconds / 60, 2), ' hrs') trip_duration,
  daysofweek[ORDINAL(EXTRACT(DAYOFWEEK FROM trip_start_timestamp))] weekday,
  EXTRACT(HOUR FROM trip_start_timestamp) hour
FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`, weekdays
WHERE trip_seconds > 0
  AND fare > 0
  AND EXTRACT(YEAR FROM trip_start_timestamp) BETWEEN 2020 AND 2022;

--- Model Results
SELECT *
FROM ML.EVALUATE(MODEL `chicago_taxi.taxi_fare_model`);

--- Testing Model to Predict Trip Cost
SELECT 
  ROUND(predicted_trip_total_cost, 2) predicted_trip_cost
FROM 
  ML.PREDICT(MODEL chicago_taxi.taxi_fare_model, 
  (
  SELECT 
  10 AS tips, 
  '1.00 hrs' AS trip_duration,
  'Mon' AS weekday, 
  17 AS hour)
  );