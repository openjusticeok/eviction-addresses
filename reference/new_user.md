# New User

Adds a new user to the database

## Usage

``` r
new_user(
  db,
  username,
  password,
  role,
  name,
  full_name,
  line1,
  line2,
  city,
  state,
  zip
)
```

## Arguments

- db:

  A database connection pool created with
  [`pool::dbPool`](http://rstudio.github.io/pool/reference/dbPool.md)

- username:

  The username

- password:

  The password

- role:

  The role of the user; either "admin" or "standard"

- name:

  The name of the user

## Value

Returns invisibly if successful

## Examples

``` r
if (FALSE) { # \dontrun{
new_user(db, "test", "test", "admin", "Test User")
} # }
```
