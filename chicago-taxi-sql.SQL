--- Average Trip Miles on Daily Hour
SELECT
  EXTRACT(HOUR FROM trip_start_timestamp) hour,
  ROUND(AVG(trip_miles), 2) avg_miles
FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
GROUP BY 1
ORDER BY 1;

--- Company with Most Trips
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

--- Cost of Trips, Fare, and Revenue per Company
SELECT
  company,
  ROUND(SUM(trip_total), 2) total_revenue,
  ROUND(SUM(trip_miles), 2) / 25 * 3.08 cost_of_trip,
  ROUND(SUM(trip_total) - SUM(trip_miles) / 25 * 3.08, 2) profit
FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
WHERE company IS NOT NULL
  AND EXTRACT(YEAR FROM trip_start_timestamp) = 2022
GROUP BY 1
ORDER BY 4 DESC;

--- Average Trip Cost, Tips, Duration per Weekday and Hour
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

--- Training Data
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
  AND EXTRACT(YEAR FROM trip_start_timestamp) = 2022;

--- Creating Model Based on 2022 Information
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
  AND EXTRACT(YEAR FROM trip_start_timestamp) = 2022;

--- Model Results
SELECT 
  ROUND(AVG(predicted_trip_total_cost), 2) predicted_trip_cost, 
  weekday, 
  hour 
FROM ML.PREDICT(MODEL `sql-practice-375701.chicago_taxi.taxi_fare_model`, 
(WITH weekdays AS(
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
  AND EXTRACT(YEAR FROM trip_start_timestamp) = 2022))
GROUP BY 2,3
ORDER BY 2,3;
