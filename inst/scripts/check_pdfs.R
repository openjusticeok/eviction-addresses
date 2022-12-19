library(googleCloudStorageR)
library(googleCloudRunner)

gcs_auth()

docs <- googleCloudStorageR::gcs_list_objects("eviction-addresses")

for (i in seq_along(docs)) {
  url <- gcs_download_url(
    object_name = docs$name[i],
    bucket = "eviction_addresses",
    public = TRUE
  )

  file <- tempfile()
  res <- httr::GET(
    url = url
  )

  if(!res$status_code == 200) {
    next()
  }

  readr::write_file(x = res$content, file = file, append = FALSE)


}
