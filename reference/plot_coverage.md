# Plot Coverage

Calculates the number of addresses entered

## Usage

``` r
plot_coverage(db, ..., .silent = FALSE)
```

## Arguments

- db:

  A database connection pool created with
  [`pool::dbPool`](http://rstudio.github.io/pool/reference/dbPool.md)

- ...:

  Additional arguments placeholder

- .silent:

  A boolean indicating whether to print the plot

## Value

A tibble with the number of addresses entered by month
