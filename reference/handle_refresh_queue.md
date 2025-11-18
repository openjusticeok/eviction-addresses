# Handle API Refresh Queue

Plumber handler for endpoint `/refresh/queue`

## Usage

``` r
handle_refresh_queue(config)
```

## Arguments

- config:

  The path to a configuration file ingested by `{config}`

## Details

This endpoint refreshes the work queue based on what it finds in the
eviction_addresses schema.
