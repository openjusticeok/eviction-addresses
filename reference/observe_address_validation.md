# Observe Address Validation

This function observes the address validation button and validates the
address.

## Usage

``` r
observe_address_validation(
  input,
  session,
  db,
  current_case,
  jwt,
  api_url,
  address_entered,
  address_validated
)
```

## Arguments

- input:

  The input object from the Shiny app

- session:

  The session object from the Shiny app

- db:

  The database connection pool

- current_case:

  The reactive value for the current case

- jwt:

  The JWT token for the API

- api_url:

  The URL for the API

- address_entered:

  The reactive values for the address entered

- address_validated:

  The reactive values for the address validated

## Value

A Shiny observeEvent object
