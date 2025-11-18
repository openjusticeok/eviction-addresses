# New DB Pool

Creates a new connection pool to the database

## Usage

``` r
new_db_pool(config = "config.yml")
```

## Arguments

- config:

  The path to a `config.yml` file to be read by the config package using
  [`config::get()`](https://rstudio.github.io/config/reference/get.html)

## Value

A database connection pool created by the pool package
