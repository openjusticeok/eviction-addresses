# New DB Connection

Creates a new connection to the database

## Usage

``` r
new_db_connection(config = "config.yml")
```

## Arguments

- config:

  The path to a `config.yml` file to be read by the config package using
  [`config::get()`](https://rstudio.github.io/config/reference/get.html)

## Value

A database connection pool created with
[`DBI::dbConnect`](https://dbi.r-dbi.org/reference/dbConnect.html)
