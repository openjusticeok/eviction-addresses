# Email Project Report

Emails a project report to a given user

## Usage

``` r
email_project_report(
  db,
  start = get_pay_period(lubridate::today())$start,
  end = get_pay_period(lubridate::today())$end,
  recipient_email,
  ...,
  .silent = FALSE
)
```

## Arguments

- db:

  A database connection pool created with
  [`pool::dbPool`](http://rstudio.github.io/pool/reference/dbPool.md)

- start:

  The start date

- end:

  The end date

- recipient_email:

  The email address to send the report to

- ...:

  Additional arguments placeholder

- .silent:

  A boolean indicating whether to print the email

## Value

Nothing
