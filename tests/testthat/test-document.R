logger::log_threshold(logger::FATAL)
googleCloudStorageR::gcs_auth(
  json_file = here::here("eviction-addresses-service-account.json"),
  email = "bq-test@ojo-database.iam.gserviceaccount.com"
)

test_that("can download valid OSCN document", {
  link <- "https://www.oscn.net/dockets/GetDocument.aspx?ct=tulsa&bc=1054112729&cn=SC-2022-16023&fmt=pdf"
  res <- download_oscn_document(link)

  expect_true(
    inherits(res, "raw")
  )
})

test_that("download from wrong site fails correctly", {
  link <- "https://www.google.com"

  expect_error(
    download_oscn_document(link)
  )
})

test_that("download of wrong type fails correctly", {
  link <- "https://www.oscn.net/dockets/GetDocument.aspx?ct=tulsa&bc=10541&cn=SC-2022-16023&fmt=pdf"
  link2 <- "https://www.oscn.net/dockets/GetDocument.aspx?ct=tulsa&bc=1054112729&cn=SC-2022-16023&fmt=png"

  expect_error(
    download_oscn_document(link),
  )

  expect_error(
    download_oscn_document(link2)
  )
})

test_that("Upload GCS document works correctly", {
  link <- "https://www.oscn.net/dockets/GetDocument.aspx?ct=tulsa&bc=1054112729&cn=SC-2022-16023&fmt=pdf"
  res <- download_oscn_document(link)

  expect_no_error(
    upload_gcs_document(res, "test.pdf")
  )
})
