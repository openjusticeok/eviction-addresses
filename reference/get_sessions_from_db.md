# Get Sessions from DB

Gets a tibble of sessions from the database for use by shinyauth

## Usage

``` r
get_sessions_from_db(db, cookie_expiry = 7)
```

## Arguments

- db:

  The database connection

- cookie_expiry:

  The cookie expiration

## Value

A tibble of session info
