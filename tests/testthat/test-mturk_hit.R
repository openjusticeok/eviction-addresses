test_that("Can delete HIT cleanly", {
  mturk_auth("config.yml")
  db <- new_db_pool("config.yml")
  withr::defer(pool::poolClose(db))

  h <- new_sample_hit(db)

  expect_no_error(
    dispose_hit(db, hit = h)
  )
})
