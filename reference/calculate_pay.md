# Calculate Pay

Calculates the pay for a given user

## Usage

``` r
calculate_pay(
  db,
  users = "all",
  start = get_pay_period(lubridate::today())$start,
  end = get_pay_period(lubridate::today())$end,
  priority_rate = 0.35,
  backlog_rate = 0.25
)
```

## Arguments

- db:

  A database connection pool created with
  [`pool::dbPool`](http://rstudio.github.io/pool/reference/dbPool.md)

- users:

  A vector of users to plot

- start:

  The start date

- end:

  The end date

## Value

A tibble with the number of addresses entered by type and the
corresponding pay

## Examples

``` r
if (FALSE) { # \dontrun{
calculate_pay(db, c("test", "test2"), lubridate::ymd("2022-12-12"), lubridate::today())
} # }
```
