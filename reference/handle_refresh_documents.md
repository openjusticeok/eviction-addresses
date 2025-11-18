# Handle API Refresh Documents

Plumber handler for endpoint `/refresh/documents/<n>`

## Usage

``` r
handle_refresh_documents(config)
```

## Arguments

- config:

  The path to a configuration file ingested by `{config}`

## Details

This endpoint refreshes documents in the eviction_addresses schema. It
then updates the work queue based on what it finds.
