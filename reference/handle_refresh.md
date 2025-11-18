# Handle API Refresh

Plumber handler for endpoint /refresh

## Usage

``` r
handle_refresh(config)
```

## Arguments

- config:

  The path to a configuration file ingested by `{config}`

## Value

A 200 if successful

## Details

This endpoint refreshes materialized views and inserts new cases and
documents into the eviction_addresses schema. It then updates the work
queue based on what it finds.
