# Observe Address Submission

This function observes the address submission button.

## Usage

``` r
observe_address_submission(
  input,
  db,
  current_case,
  current_user,
  address_entered,
  address_validated
)
```

## Arguments

- input:

  The input object

- db:

  The database connection

- current_case:

  The current case

- current_user:

  The current user

- address_entered:

  The address entered by the user

- address_validated:

  The address validated by the API

## Value

A Shiny observer object
