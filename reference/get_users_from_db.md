# Get Users from DB

Gets a tibble of users from the database to be used by shinyauth

## Usage

``` r
get_users_from_db(db)
```

## Arguments

- db:

  A database connection pool created with
  [`pool::dbPool`](http://rstudio.github.io/pool/reference/dbPool.md)

## Value

A tibble of user info
