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

test_that("get_pay_period works with default weekly periods", {
  # Test default weekly behavior
  result1 <- get_pay_period(lubridate::ymd("2023-01-01"))  # Sunday
  expect_equal(result1$start, lubridate::ymd("2023-01-01"))
  expect_equal(result1$end, lubridate::ymd("2023-01-07"))
  expect_equal(lubridate::wday(result1$start), 1)  # Sunday
  expect_equal(lubridate::wday(result1$end), 7)    # Saturday

  # Test mid-week
  result2 <- get_pay_period(lubridate::ymd("2023-01-04"))  # Wednesday
  expect_equal(result2$start, lubridate::ymd("2023-01-01"))
  expect_equal(result2$end, lubridate::ymd("2023-01-07"))

  # Test next week
  result3 <- get_pay_period(lubridate::ymd("2023-01-08"))  # Next Sunday
  expect_equal(result3$start, lubridate::ymd("2023-01-08"))
  expect_equal(result3$end, lubridate::ymd("2023-01-14"))
})

test_that("get_pay_period works with custom periods", {
  # Test 2-week period
  result1 <- get_pay_period(lubridate::ymd("2023-01-04"), period = "2 weeks")
  expect_equal(result1$start, lubridate::ymd("2023-01-01"))
  expect_equal(result1$end, lubridate::ymd("2023-01-14"))

  # Test next 2-week period
  result2 <- get_pay_period(lubridate::ymd("2023-01-15"), period = "2 weeks")
  expect_equal(result2$start, lubridate::ymd("2023-01-15"))
  expect_equal(result2$end, lubridate::ymd("2023-01-28"))

  # Test 1 month period
  result3 <- get_pay_period(lubridate::ymd("2023-01-15"), period = "1 month")
  expect_equal(result3$start, lubridate::ymd("2023-01-01"))
  expect_equal(result3$end, lubridate::ymd("2023-01-30"))
})

test_that("get_pay_period handles character dates", {
  result <- get_pay_period("2023-01-10")
  expect_equal(result$start, lubridate::ymd("2023-01-08"))
  expect_equal(result$end, lubridate::ymd("2023-01-14"))
})

test_that("get_pay_period error handling works", {
  # Test invalid date type
  expect_error(
    get_pay_period(123),
    "`date` must be a character or Date"
  )

  # Test invalid period
  expect_error(
    get_pay_period(lubridate::ymd("2023-01-01"), period = "0 weeks"),
    "`period` must result in a positive number of days"
  )
})

test_that("get_pay_period maintains backward compatibility", {
  # Test that old behavior can be reproduced with explicit parameters
  result <- get_pay_period(
    lubridate::ymd("2023-01-15"),
    pay_period_start_date = lubridate::ymd("2023-01-02"),
    period = "2 weeks"
  )
  expect_equal(result$start, lubridate::ymd("2023-01-02"))
  expect_equal(result$end, lubridate::ymd("2023-01-15"))
})
