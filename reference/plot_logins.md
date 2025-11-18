# Plot Logins

Plots the number of logins per day

## Usage

``` r
plot_logins(
  db,
  users,
  start = lubridate::ymd("2022-12-12"),
  end = lubridate::today(),
  .silent = FALSE
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

A ggplot object

## Examples

``` r
if (FALSE) { # \dontrun{
plot_logins(db, c("test", "test2"), lubridate::ymd("2022-12-12"), lubridate::today())
} # }
```
