# Render Pay Report

Renders a pay report for a given user

## Usage

``` r
render_pay_report(
  db,
  users = "all",
  start = get_pay_period(lubridate::today())$start,
  end = get_pay_period(lubridate::today())$end
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
