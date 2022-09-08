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

test_that("Create HIT Type fails with no aws keys", {
  withr::local_envvar(
    list(
      AWS_ACCESS_KEY_ID = NULL,
      AWS_SECRET_ACCESS_KEY = NULL
    )
  )

  expect_error(
    create_hit_type(),
    regexp = "(?i)aws keys"
  )
})

test_that("Create HIT Type returns a string", {
  skip_on_covr()
  skip_if_no_config()

  res <- create_hit_type()

  expect_vector(res, ptype = "character", size = 1)
})

test_that("Create HIT Type fails on bad response from pyMTurkR", {
  mockery::stub(
    create_hit_type,
    'pyMTurkR::CreateHITType',
    errorCondition("request failed")
  )
  expect_error(create_hit_type(), regexp = "(?i)response from pyMTurkR")

  mockery::stub(
    create_hit_type,
    'pyMTurkR::CreateHITType',
    NULL
  )
  expect_error(create_hit_type(), regexp = "(?i)response from pyMTurkR")

  mockery::stub(
    create_hit_type,
    'pyMTurkR::CreateHITType',
    list(test = 1, b = "two")
  )
  expect_error(create_hit_type(), regexp = "(?i)response from pyMTurkR")

  mockery::stub(
    create_hit_type,
    'pyMTurkR::CreateHITType',
    list(HITTypeId = "blah", Valid = "test")
  )
  expect_error(create_hit_type(), "is not TRUE")

  mockery::stub(
    create_hit_type,
    'pyMTurkR::CreateHITType',
    list(HITTypeId = "blah", Valid = F)
  )
  expect_error(create_hit_type(), "is not TRUE")

  mockery::stub(
    create_hit_type,
    'pyMTurkR::CreateHITType',
    list(HITTypeId = 1, Valid = T)
  )
  expect_error(create_hit_type(), "is not a string")
})

test_that("Create HIT Type returns correct value with mock pyMTurkR response", {
  mockery::stub(
    create_hit_type,
    'pyMTurkR::CreateHITType',
    list(HITTypeId = "test_id", Valid = T)
  )
  expect_equal(create_hit_type(), "test_id")
})

test_that("Render document links rejects args correctly", {
  links <- c(1, 2, 3)
  expect_error(render_document_links(links), "is not a character")

  links <- NA_character_
  expect_error(render_document_links(links), "missing values")

  links <- NULL
  expect_error(render_document_links(links), "empty dimension")
})

test_that("Render documents returns expected value with sample links", {
  links <- c(
    "https://google.com",
    "https://twitter.com"
  )

  expect_equal(
    render_document_links(links),
    "<a href=\"https://google.com\" target=\"_blank\">Document 1</a><br><a href=\"https://twitter.com\" target=\"_blank\">Document 2</a>"
  )
})


