# Send PostGrid Request

Send PostGrid Request

## Usage

``` r
send_postgrid_request(config = NULL, address = list(), geocode = T)
```

## Arguments

- config:

  The path of a `config.yml` file with section to be parsed by
  `config::get(value = "postgrid")`

- address:

  A list with elements `line1`, `line2`, `city`, `provinceOrState`, and
  `country`

- geocode:

  A flag (logical vector of length one) indicating whether to geocode
  the address. Uses another Postgrid unit. Defaults to `TRUE`

## Value

A PostGrid response
