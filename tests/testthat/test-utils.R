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
