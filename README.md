# Day-Ahead Electricity Price Forecasting for the Iberian Market (OMIE)

Quarter-hourly forecasts of the day-ahead electricity price in the Iberian market, written in R. The project downloads the market results published by [OMIE](https://www.omie.es), fits a **LEAR-LASSO** model (one LASSO regression per quarter-hour, using the prices of the previous seven days as predictors) and compares it with three naive benchmarks over the most recent 28 days.

> In the code, a *segment* is one of the 96 quarter-hour periods of a day.

## What it does

1. **Data.** Downloads the daily price files from OMIE and keeps a local table that is updated incrementally on every run.
2. **Features.** Builds a design matrix where each day is described by the 96 quarter-hourly prices of each of the seven previous days.
3. **Model.** Selects one LASSO penalty per quarter-hour by expanding-window validation.
4. **Evaluation.** Tests the model on the last 28 days with daily recalibration and compares MAE and RMSE with the benchmarks.
5. **Forecast.** Refits on all available data and returns the 96 prices forecast for tomorrow.

## Project structure

```
.
├── main.R                  # Runs the full pipeline
├── src/
│   ├── omie_data.R         # Download, parsing and incremental update of OMIE data
│   ├── generate_matrix.R   # Lagged design matrix
│   ├── LASSO.R             # Penalty selection, test predictions, forecast for tomorrow
│   ├── Benchmarks.R        # Naive forecasts
│   └── Metrics.R           # Error metrics, comparison table and plots
└── data/Omie/              # Created at run time: raw files and omie_file.rds
```

Every script except `main.R` only defines functions, so they can be sourced and reused independently.

## Requirements

- R, with an internet connection to reach omie.es
- The `glmnet` package

```r
install.packages("glmnet")
```

## Usage

Run from the project folder, since all paths are relative to it.

From a terminal:

```bash
Rscript main.R
```

The forecast and the results table are printed to the console and the plots are written to `Rplots.pdf`.

From an R session:

```r
source("main.R", print.eval = TRUE)
```

`main.R` produces, in this order:

| Call | Output |
| --- | --- |
| `prediction()` | 96 × 1 matrix with tomorrow's forecast in €/MWh, one row per quarter-hour (`00:00` to `23:45`) |
| `show_metrics_lasso()` | Plots of the model's MAE and RMSE by quarter-hour and its MAE by test day |
| `show_mae_rmse_average()` | Table with the overall MAE and RMSE of the model and the three benchmarks |
| `show_metrics_segments()` | Plot comparing the MAE by quarter-hour of the four methods |

The first run downloads one file per day since 1 October 2025 and then selects the penalties, so it takes a while; progress is printed to the console. Later runs only download the missing days, but the model is fitted again each time.

The pipeline needs at least 186 days of history: 7 for the lags, 150 for the initial training window, 1 or more for validation and 28 for the test.

### Configuration

| Setting | Where | Default |
| --- | --- | --- |
| Lags used as predictors | `lags` in `main.R` | `1:7` |
| Test days | `nTest` in `main.R` | `28` |
| Initial training window for validation | `initial_n` argument of `get_lambda()` | `150` |
| Data folder | `download_folder` argument of `get_data()` | `"data/Omie"` |
| First day downloaded | `start_date` in `get_data()` | `2025-10-01` |

## Data

- **Source.** OMIE's `marginalpdbc_YYYYMMDD.v` files, which hold the marginal price of the day-ahead market in €/MWh. For each day the script tries versions `.1` to `.4` and keeps the first one that downloads.
- **Period.** From 1 October 2025, the first delivery day with 15-minute resolution in the European day-ahead market, up to the current date.
- **Storage.** `data/Omie/omie_file.rds` holds a matrix with 96 rows (quarter-hours, labeled `00:00` to `23:45`) and one column per day (labeled `dd/mm/yy`).
- **Clock changes.** Every day is forced to 96 periods. On the 100-period day in autumn, the repeated hour is averaged; on the 92-period day in spring, the missing hour is filled by linear interpolation between the neighboring periods.

## Method

### Features

For a target day `d`, the predictors are the 96 prices of each of the days `d-1` to `d-7`, which gives 7 × 96 = 672 columns. The response is the vector of 96 prices of day `d`.

### LEAR-LASSO

The model follows the LEAR (LASSO-Estimated AutoRegressive) idea of Lago et al. (2021) in a purely autoregressive form: each quarter-hour `q` has its own linear model on all 672 lagged prices, and the L1 penalty selects the relevant ones.

```math
\hat{p}_{d,q} = \beta_{0}^{(q)} + \sum_{l=1}^{7} \sum_{j=1}^{96} \beta_{l,j}^{(q)} \, p_{d-l,\,j}
```

Models are fitted with `glmnet` (`alpha = 1`, standardized predictors, intercept).

**Penalty selection.** The last 28 days are set aside for testing. On the remaining days, and separately for each quarter-hour:

1. A LASSO path is fitted on the first 150 days to obtain the grid of penalties.
2. For every later day, the model is fitted on all previous days and that day is predicted with every penalty of the grid.
3. The penalty with the lowest mean absolute error over those days is kept.

**Test.** For each of the 28 test days, the 96 models are refitted on all earlier days with their selected penalty, which reproduces a daily recalibration with an expanding window. The penalties never see the test days.

**Forecast.** `prediction()` refits the 96 models on all available data and predicts tomorrow from the last seven days, today included.

### Benchmarks

| Name | Forecast for each quarter-hour of day `d` |
| --- | --- |
| Naive d-1 | Price of the same quarter-hour on the previous day |
| Naive d-7 | Price of the same quarter-hour one week earlier |
| 4 weeks | Mean of the same quarter-hour on days `d-7`, `d-14`, `d-21` and `d-28` |

All methods are scored on the same 28 days with MAE and RMSE, computed overall, by quarter-hour and by day. Because the test window is always the most recent 28 days, the figures change with the date of the run.

## Functions

| File | Function | Description |
| --- | --- | --- |
| `omie_data.R` | `download_omie(date, download_folder)` | Downloads the file of one day and returns its path |
| | `read_omie_file(file_path)` | Parses a file into a vector of 96 prices |
| | `get_data(download_folder = "data/Omie")` | Creates or updates the price table and returns it |
| `generate_matrix.R` | `generate_lag_matrix(data, lags = 1:7)` | Returns `X`, `Y` and the day indices |
| `LASSO.R` | `select_lambda(X_dev, Y_dev, q, days, initial_n = 150)` | Selects the penalty for quarter-hour `q` |
| | `get_lambda(X_dev, Y_dev, days, initial_n = 150)` | Selects the penalties of the 96 quarter-hours |
| | `test(X, Y, i_Test, lambda_opt)` | Predictions for the test days with daily recalibration |
| | `prediction(X, Y, lambda_opt, omie_data)` | Forecast for tomorrow |
| `Benchmarks.R` | `predict_naive(omie_data, test_days, lag)` | Prices of `lag` days earlier |
| | `predict_weekly_average(omie_data, test_days)` | Mean of the four previous weeks |
| `Metrics.R` | `calc_metrics(real, pred)` | MAE and RMSE: overall, by quarter-hour and by day |
| | `show_metrics_lasso(metrics_lasso)` | Plots of the model's errors |
| | `show_mae_rmse_average(...)` | Comparison table |
| | `show_metrics_segments(...)` | Comparison plot by quarter-hour |

## Notes

- The model uses past prices only. It has no exogenous inputs such as demand, wind and solar forecasts or gas prices.
- `prediction()` builds tomorrow's predictors by shifting the last row of the design matrix one day, so it expects consecutive lags starting at 1 (`1:k`).
- `data/` contains downloaded files and can be excluded from version control.

## Work in progress

These parts exist but are not in the repository yet:

- **Exploratory analysis.** Price distribution, profiles by quarter-hour and by day, and autocorrelation at the daily and weekly lags.
- **XGBoost alternative.** Gradient boosting with the same validation scheme. In first tests on single quarter-hours it did not improve on the LASSO.

## References

- J. Lago, G. Marcjasz, B. De Schutter and R. Weron, "Forecasting day-ahead electricity prices: A review of state-of-the-art algorithms, best practices and an open-access benchmark", *Applied Energy*, 293, 2021.
- J. Friedman, T. Hastie and R. Tibshirani, "Regularization paths for generalized linear models via coordinate descent", *Journal of Statistical Software*, 33(1), 2010.
- OMIE, Iberian electricity market operator: <https://www.omie.es>
