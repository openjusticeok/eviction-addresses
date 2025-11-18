# Email Pay Report

Emails a pay report for the given users using the package `{blastula}`

## Usage

``` r
email_pay_report(
  db,
  users,
  start = get_pay_period(lubridate::today())$start,
  end = get_pay_period(lubridate::today())$end,
  recipient_email
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

- email:

  The email address to send the report to

## Value

Nothing
