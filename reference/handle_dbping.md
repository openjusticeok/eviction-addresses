# Handle DB Ping

A plumber handler that pings the database

## Usage

``` r
handle_dbping(db)
```

## Arguments

- db:

  A database connection pool created with
  [`pool::dbPool`](http://rstudio.github.io/pool/reference/dbPool.md)

## Value

A plumber handler that returns a 200 status code and a message that the
database is connected

## Details

This endpoint returns a simple "db pong" message after pinging the
database
