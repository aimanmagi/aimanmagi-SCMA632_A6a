setwd('G:\\VCU\\Bootcamp Assignment\\A6\\A6a')

# Function to auto-install and load packages
install_and_load <- function(packages) {
  for (package in packages) {
    if (!require(package, character.only = TRUE)) {
      install.packages(package, dependencies = TRUE)
    }
    library(package, character.only = TRUE)
  }
}


# List of packages to install and load
packages <- c("quantmod", "zoo", "forecast", "ggplot2")

# Call the function
install_and_load(packages)

# Load the data
data_df <- read.csv("ASIANPAINT.NS.csv")

# Display the first few rows of the data
head(data_df)

data_df$Date <- as.Date(data_df$Date)

# Display the first few rows of the data
head(data_df)

# Check for missing values
print("Missing values before interpolation:")
print(sum(is.na(data_df$Close)))

# Interpolate missing values
data_df$Close <- na.interp(data_df$Close)

# Check for missing values again
print("Missing values after interpolation:")
print(sum(is.na(data_df$Close)))

# Plot the data
ggplot(data_df, aes(x = Date, y = Close)) + 
  geom_line() + 
  labs(title = "Asianpaints Close price", x = "Date", y = "Close Price")

# Split the data into training and test sets
set.seed(999)
train_index <- sample(nrow(data_df), 0.7 * nrow(data_df))
train_data <- data_df[train_index, ]
test_data <- data_df[-train_index, ]

# Display the sizes of the train and test datasets
print(paste("Training data size:", nrow(train_data)))
print(paste("Test data size:", nrow(test_data)))

# Display the first few rows of the train and test datasets
print("Training data:")
head(train_data)
print("Test data:")
head(test_data)

# Convert the data to monthly frequency
monthly_data <- aggregate(Close ~ format(Date, "%Y-%m"), data_df, mean)
colnames(monthly_data) <- c("Month", "Close")
# Ensure 'Month' is in date format and no missing values in 'Close'
monthly_data$Month <- as.Date(paste0(monthly_data$Month, "-01"), format="%Y-%m-%d")

# Check for missing or non-finite values in 'Close'
if (any(!is.finite(monthly_data$Close))) {
  stop("There are non-finite values in the 'Close' column.")
}

# Plot the monthly data
ggplot(data = monthly_data, aes(x = Month, y = Close)) +
  geom_line() +
  labs(title = "Asianpaints Monthly Close Price", x = "Date", y = "Close Price") +
  theme_minimal()

# Ensure necessary packages are installed and loaded
install_and_load(c("zoo", "forecast", "ggplot2"))

# Convert the monthly data to a time series object
monthly_ts <- ts(monthly_data$Close, start = c(as.numeric(format(min(monthly_data$Month), "%Y")), as.numeric(format(min(monthly_data$Month), "%m"))), frequency = 12)

# Fit the Holt-Winters model
holt_winters_model <- HoltWinters(monthly_ts, seasonal = "additive")

# Forecast for the next year (12 months)
holt_winters_forecast <- forecast(holt_winters_model, h = 12)

# Plot the forecast
plot(holt_winters_forecast, main = "Holt-Winters Forecast", xlab = "Date", ylab = "Close Price")
lines(monthly_ts, col = "blue")
legend("topleft", legend = c("Observed", "Holt-Winters Forecast"), col = c("blue", "red"), lty = 1:2)

# Ensure necessary packages are installed and loaded
install_and_load(c("quantmod", "forecast", "zoo", "ggplot2", "TTR"))
library(tidyr)
# Load the data
data_df <- read.csv("ASIANPAINT.NS.csv")
data_df$Date <- as.Date(data_df$Date)

# Interpolate missing values
data_df$Close <- na.approx(data_df$Close)

# Convert the data to daily frequency
daily_data <- data_df %>%
  complete(Date = seq.Date(min(Date), max(Date), by="day")) %>%
  fill(Close, .direction = "downup")

# Interpolate missing values in the daily data (if any)
daily_data$Close <- na.approx(daily_data$Close)

# Display the first few rows of the daily data
head(daily_data)

library(dplyr)
# Interpolate missing values in the daily data (if any)
daily_data$Close <- na.approx(daily_data$Close)

# Drop unnecessary columns
daily_data <- daily_data %>% 
  select(Date, Close, Type)

# Display the first few rows of the daily data
head(daily_data)
# Save the daily data to a new CSV file
write.csv(daily_data, file = "daily_ASIANPAINT.NS.csv", row.names = FALSE)

# Convert to time series object
daily_ts <- ts(daily_data$Close, frequency = 365, start = c(as.numeric(format(min(daily_data$Date), "%Y")), as.numeric(format(min(daily_data$Date), "%j"))))

# Fit the ARIMA model
arima_model <- auto.arima(daily_ts)

# Diagnostic checks for ARIMA model
tsdiag(arima_model)

library(forecast)
arima_forecast <- forecast(arima_model)

# Prepare data for plotting
forecast_df <- data.frame(Date = seq(max(daily_data$Date) + 1, by = "day", length.out = 730),
                          Close = as.numeric(arima_forecast$mean),
                          Type = "Forecast")

# Combine observed and forecasted data
daily_data$Type <- "Observed"
forecast_df$Type <- "Forecast"
#plot_data <- rbind(daily_data~daily_data$Date, daily_data$Close, daily_data$Type, forecast_df)
plot_data <- rbind(
  daily_data[, c("Date", "Close", "Type")],
  forecast_df
)
print(forecast_df)

# Clear any existing graphics
dev.off()

# Plot the ARIMA forecast with observed data
ggplot() +
  geom_line(data = plot_data, aes(x = Date, y = Close, color = Type, linetype = Type), size = 1) +
  labs(title = "ARIMA Forecast", x = "Date", y = "Close Price") +
  scale_color_manual(values = c("Observed" = "blue", "Forecast" = "red")) +
  scale_linetype_manual(values = c("Observed" = "solid", "Forecast" = "dashed")) +
  theme_minimal()

# Train a decision tree model
model <- rpart(Close ~ Date, data = train_data, method = "anova")
predictions_dt <- predict(model, test_data)

# Display the first few rows of the predictions
head(predictions_dt)

# Install necessary package
install_and_load(c("randomForest"))

# Train a random forest model
model_rf <- randomForest(Close ~ Date, data = train_data)
predictions_rf <- predict(model_rf, test_data)

# Display the first few rows of the predictions
head(predictions_rf)

# Plot predictions vs true values
test_data$Predictions_DT <- predictions_dt
test_data$Predictions_RF <- predictions_rf

ggplot(test_data, aes(x = Date)) +
  geom_line(aes(y = Close, color = "True Values")) +
  geom_line(aes(y = Predictions_DT, color = "Decision Tree Predictions")) +
  geom_line(aes(y = Predictions_RF, color = "Random Forest Predictions")) +
  labs(title = "Decision Tree & Random Forest: Predictions vs True Values", 
       x = "Time", 
       y = "Close Price") +
  scale_color_manual("", 
                     breaks = c("True Values", "Decision Tree Predictions", "Random Forest Predictions"),
                     values = c("blue", "red", "green")) +
  theme_minimal()

# Ensure necessary packages are installed and loaded
install_and_load(c("zoo", "forecast", "ggplot2"))

# Convert the monthly data to a time series object
monthly_ts <- ts(monthly_data$Close, start = c(as.numeric(format(min(monthly_data$Month), "%Y")), as.numeric(format(min(monthly_data$Month), "%m"))), frequency = 12)

# Decompose the time series using additive model
additive_decompose <- decompose(monthly_ts, type = "additive")
plot(additive_decompose)

# Decompose the time series using multiplicative model
multiplicative_decompose <- decompose(monthly_ts, type = "multiplicative")
plot(multiplicative_decompose)


