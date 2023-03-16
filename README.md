<p align="center">
<img src="./images/1_Xz0UKJ3zec1S4k11lO3EjQ.jpeg" width=800>
</p>

This code is a series of SQL queries that analyze the Chicago Taxi Trips dataset, available in BigQuery's public datasets. The queries extract different statistics, such as the number of trips per year, the average trip distance and speed, the total revenue and profit of taxi companies, and the average trip cost, tips, and duration per weekday and hour. The code also creates a temporary table to save the result of one of the queries and uses it to calculate the average number of taxi trips per quartile. Finally, the code trains a linear regression model to predict the total cost of a taxi trip based on other features such as the tip, duration, weekday, and hour.

The code uses common SQL constructs such as CTEs, window functions, table aliases, and joins. It also uses some BigQuery-specific features, such as the ORDINAL function to retrieve the position of an array element, and the ML.EVALUATE function to evaluate a machine learning model. The queries apply several filtering conditions to exclude rows with null values or invalid data, such as negative distances, fares, or trip durations.

**Can this BigQuery Linear Regression Model Predict Chicago Taxi Trip Costs?**

As the ridesharing industry continues to grow, taxi companies are turning to data-driven approaches to optimize pricing, reduce costs, and improve customer experiences. In this context, building accurate predictive models for taxi trip costs is a critical task.

In this project, I built a linear regression model using BigQuery to predict the cost of Chicago taxi trips. The model was trained on a dataset containing trip information from 2020 to 2022, including trip duration, day of the week, and hour of the day. I used evaluation metrics such as mean absolute error, mean squared error, and R-squared to assess the model's performance.

The results of the model were mixed. The mean absolute error was 6.835, indicating that on average, the model's predictions were off by around $7. The median absolute error of 3.2974 suggests that the model is better at predicting some trips than others, but overall its predictions tend to be somewhat inaccurate. The R-squared value of 0.0479 indicates that the model explains only a small amount of the variance in the target variable, and could benefit from additional features or more complex modeling techniques.

Overall, I can conclude that the model has some predictive power, but there is definitely room for improvement. Expanding the date range of the training data, adding new features, or trying more complex modeling techniques could help to improve the model's accuracy and predictive power.

This project demonstrates how BigQuery can be used to build predictive models for taxi trip costs, and highlights some of the challenges and limitations of linear regression models.
