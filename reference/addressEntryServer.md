# Address Entry Module Server

Server for the address entry module

## Usage

``` r
addressEntryServer(id, config, db, current_case, current_user)
```

## Arguments

- id:

  The module ID

- config:

  The path to a config file ingested by `{config}`

- db:

  The database connection pool

- current_case:

  The reactive value for the current case

- current_user:

  The reactive value for the current user

## Value

The server for the address entry module
