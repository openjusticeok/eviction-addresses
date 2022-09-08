options(
  pyMTurkR.sandbox = T,
  pyMTurkR.verbose = F
)
logger::log_threshold(FATAL)


test_that("MTurk auth succeeds with valid config", {
  #skip_on_covr()
  #skip_if_no_config()

  #vcr::use_cassette("mturk_auth", {
    res <- mturk_auth("config.yml")
  #})
  expect_true(res)
})

test_that("MTurk auth fails on no config or env variables", {
  withr::local_envvar(
    list(
      AWS_ACCESS_KEY_ID = NULL,
      AWS_SECRET_ACCESS_KEY = NULL
    )
  )

  res <- mturk_auth()

  expect_false(res)
})

test_that("Create HIT Type works as expected", {
  skip_on_covr()
  skip_if_no_config()

  mturk_auth("config.yml")
  testthat::expect_error(
    create_hit_type(),
    NA
  )
})

