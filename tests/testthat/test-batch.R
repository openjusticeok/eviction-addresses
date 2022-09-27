test_that("Batch case works", {
  mturk_auth("config.yml")

  db <- new_db_pool("config.yml")
  withr::defer(pool::poolClose(db))

  ht <- new_hit_type()

  mockery::stub(
    batch_case,
    "new_case_from_queue",
    '{"district": "TULSA", "case_number": "SC-2022-1"}'
  )

  expect_no_error(
    batch_case(db, ht)
  )
})
