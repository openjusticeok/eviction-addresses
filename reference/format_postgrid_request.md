# Format PostGrid Request

Format PostGrid Request

## Usage

``` r
format_postgrid_request(
  line1 = NA_character_,
  line2 = NA_character_,
  city = NA_character_,
  state = "ok",
  zip = NA_character_,
  country = "us",
  street_number = NA_character_,
  street_direction = NA_character_,
  street_name = NA_character_,
  street_type = NA_character_,
  unit = NA_character_
)
```

## Arguments

- line1:

  The first line of an address

- line2:

  The second line of an address (e.g. unit/suite/apartment)

- city:

  The city of the address

- state:

  The state of the address

- zip:

  The five-digit zip code of the address

- country:

  The two letter country code

- street_number:

  The building number of the address's street

- street_direction:

  The street direction of the address

- street_name:

  The name of the address's street (including post-direction, e.g. 68th
  E)

- street_type:

  The type of the address's street (e.g. street/avenue/place)

- unit:

  The unit type and value of an address (e.g. APT 13, UNIT C)

## Value

A list with fields suitable for a PostGrid request
