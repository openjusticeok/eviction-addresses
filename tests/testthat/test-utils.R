test_obj <- data.frame(
  test1 = c(1, 2, 3),
  test2 = c(3, 2, 1)
)

test_that("Has names works as expected", {
  res <- has_names(test_obj, c("test1", "test2"))
  expect_true(res)
})

test_that("Has names fails as expected", {
  res <- has_names(test_obj, c("test1", "test3"))
  expect_false(res)
})

test_that("Lat/Lon match test works", {
  d <- tibble::tibble(
    lat = c(36.1234, 36.1235),
    lon = c(85.1234, 85.1235)
  )

  res <- has_latlon_match(d)
  expect_true(res)

  res <- has_latlon_match(d, tolerance = 0)
  expect_false(res)

  d <- tibble::tibble(
    lat = c(36.1234, 36.1235),
    lon = c(85.1234, NA)
  )

  expect_error(
    has_latlon_match(d)
  )

  d <- tibble::tibble(
    lat = c(36.1234, 36.1233),
    lon = c(85.1234, 85.1235)
  )

  expect_true(
    has_latlon_match(d)
  )
})
