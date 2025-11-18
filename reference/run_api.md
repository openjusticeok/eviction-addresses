# Run API

Starts the eviction address api

## Usage

``` r
run_api(config, ..., .background = FALSE)
```

## Arguments

- config:

  The path to a configuration file ingested by `{config}`

- ...:

  Additional arguments passed to
  [`plumber::pr_run`](https://www.rplumber.io/reference/pr_run.html),
  e.g. port = 8080

- .background:

  Whether to start the API in a background process

## Value

Nothing
