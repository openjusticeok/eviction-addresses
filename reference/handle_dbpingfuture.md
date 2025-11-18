# Handle Future DB Ping

A plumber handler that pings the database in a background process,
returning before returning a response

## Usage

``` r
handle_dbpingfuture(config)
```

## Arguments

- config:

  The path to a configuration file ingested by `{config}`

## Value

A plumber handler that returns a 202 status code and a message that the
request has been queued
