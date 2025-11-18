# Get Pay Period

Gets the pay period for a given date

## Usage

``` r
get_pay_period(
  date,
  pay_period_start_date = lubridate::ymd("2023-01-01"),
  period = "1 week"
)
```

## Arguments

- date:

  A date

- pay_period_start_date:

  The reference start date for pay periods. Defaults to a Sunday
  (2023-01-01)

- period:

  The length of the pay period as a string (e.g., "1 week", "2 weeks",
  "1 month"). Defaults to "1 week"

## Value

A list with two values `start` and `end` which are the first and last
days of the pay period containing `date`. Pay periods start on Sunday
and go through Saturday.
