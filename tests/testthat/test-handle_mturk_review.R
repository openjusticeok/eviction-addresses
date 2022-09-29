log_threshold(TRACE)

test_that("Handle MTurk Review correctly runs when no reviewable hits found", {
  skip_if_no_mturk()
  skip_if_no_db()

  db <- new_db_pool("config.yml")
  withr::defer(pool::poolClose(db))

  mockery::stub(handle_mturk_review, "get_reviewable_hits", character())

  expect_no_error({
    f <- handle_mturk_review(db, "config.yml")
    f()
  })
})

test_that("Handle MTurk Review correctly runs when invalid reviewable HIT found", {
  skip_if_no_mturk()
  skip_if_no_db()

  db <- new_db_pool("config.yml")
  withr::defer(pool::poolClose(db))

  mockery::stub(handle_mturk_review, "get_reviewable_hits", c("FAKEHIT"))

  expect_no_error({
    f <- handle_mturk_review(db, "config.yml")
    f()
  })
})


