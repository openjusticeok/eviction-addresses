# Render Project Report

Renders a project report for a given user

## Usage

``` r
render_project_report(
  db,
  users = "all",
  start = get_pay_period(lubridate::today())$start,
  end = get_pay_period(lubridate::today())$end,
  ...,
  .silent = FALSE
)
```

## Arguments

- db:

  A database connection pool created with
  [`pool::dbPool`](http://rstudio.github.io/pool/reference/dbPool.md)

- users:

  A vector of users to include in the report

- start:

  The start date

- end:

  The end date

## Value

A rendered project report
