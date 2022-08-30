ans_addresses <- list(
  ans_one = list(
    line1 = "13243 S 68 E AVE",
    line2 = "",
    city = "BIXBY",
    provinceOrState = "OK",
    postalOrZip = "74008",
    country = "US"
  ),
  ans_two = list(
    line1 = "2513 MILLER AVE",
    line2 = "SUITE C",
    city = "ANN ARBOR",
    provinceOrState = "MI",
    postalOrZip = "48103",
    country = "US"
  )
)

test_that("postgrid formatting succeeds with line vars", {
  address <- list()

  address$ans_one <- format_postgrid_request(
    line1 = "13243 S 68 E AVE",
    city = "Bixby",
    state = "ok",
    zip = "74008"
  )

  address$ans_two <- format_postgrid_request(
    line1 = "2513 Miller AVE",
    line2 = "Suite C",
    city = "Ann Arbor",
    state = "mi",
    zip = "48103"
  )

  expect_identical(address, ans_addresses)
})

test_that("postgrid formatting succeeds with street vars", {
  address <- list()

  address$ans_one <- format_postgrid_request(
    street_number = "13243",
    street_direction = "S",
    street_name = "68 E",
    street_type = "AVE",
    city = "Bixby",
    state = "ok",
    zip = "74008"
  )

  address$ans_two <- format_postgrid_request(
    street_number = "2513",
    street_direction = "",
    street_name = "Miller",
    street_type = "AVE",
    unit = "Suite C",
    city = "Ann Arbor",
    state = "MI",
    zip = "48103"
  )

  expect_identical(address, ans_addresses)
})

test_that("postgrid formatting fails with line and street vars", {
  expect_error(
    format_postgrid_request(
      line1 = "13243 S 68 E AVE",
      line2 = "",
      city = "Bixby",
      state = "ok",
      zip = "74008",
      street_number = "13243"
    )
  )
})

test_that("postgrid formatting errors with neither vars", {
  expect_error(
    format_postgrid_request(
      city = "Bixby",
      state = "ok",
      zip = "74008"
    )
  )
})
