logger::log_threshold(FATAL)

test_that("MTurk auth fails on no config or env variables", {
  withr::local_envvar(
    list(
      AWS_ACCESS_KEY_ID = NULL,
      AWS_SECRET_ACCESS_KEY = NULL
    )
  )

  res <- auth_mturk()

  expect_false(res)
})

