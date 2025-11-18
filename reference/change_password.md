# Change Password

Changes a user's password

## Usage

``` r
change_password(db, username, old_password, new_password)
```

## Arguments

- db:

  A database connection pool created with
  [`pool::dbPool`](http://rstudio.github.io/pool/reference/dbPool.md)

- username:

  The username

- old_password:

  The old password

- new_password:

  The new password

## Value

Returns invisibly if successful

## Examples

``` r
if (FALSE) { # \dontrun{
change_password(db, "test", "test", "test2")
} # }
```
