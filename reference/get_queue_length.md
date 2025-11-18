# Get Queue Length

Get Queue Length

## Usage

``` r
get_queue_length(db, status = "available")
```

## Arguments

- db:

  A database connection pool

- status:

  A character string indicating whether to count all cases in the queue
  or only those that are available for processing. Defaults to
  "available".

## Value

The length of the queue. An integer.
