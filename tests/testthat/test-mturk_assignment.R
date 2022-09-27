test_that("Can get HIT assignments correctly when none are submitted", {
  mturk_auth("config.yml")
  db <- new_db_pool("config.yml")
  withr::defer(pool::poolClose(db))

  h <- new_sample_hit(db)

  a <- get_hit_assignments(h)

  expect_type(a, "character")
  expect_length(a, 0L)

  dispose_hit(db, hit = h)
})


# test_that("Can get Assignment status", {
#
# })
#
#
# test_that("Can check assignment record exists", {
#
# })
#
#
# test_that("Can add an assignment record", {
#
# })
#
#
# test_that("Can update an assignment record", {
#
# })


# test_that("Correctly parses an assignment answer", {
#
# })
#
#
# test_that("Can get parsed assignment answer", {
#
# })
#
#
# test_that("Correctly reviews an assignment", {
#
# })
#
#
# test_that("Can review and compare hit assignments in one go", {
#
# })
#
#
# test_that("Correctly compares assignment answers", {
#
# })


