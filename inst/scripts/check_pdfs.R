library(googleCloudStorageR)
library(googleCloudRunner)
library(tidyverse)

gcs_auth()

docs <- googleCloudStorageR::gcs_list_objects("eviction-addresses")

empties <- docs |>
  as_tibble() |>
  mutate(size_num = str_extract(size, "\\d+\\.\\d+") |>
           as.numeric()) |>
  filter(size_num == 1.2, !str_detect(size, "Mb")) |>
  pull(name)

walk(empties, function(x){print(x); gcs_delete_object(x, bucket = "eviction-addresses")})

# for (i in seq_along(docs)) {
#   url <- gcs_download_url(
#     object_name = docs$name[i],
#     bucket = "eviction_addresses",
#     public = TRUE
#   )
#
#   file <- tempfile()
#   res <- httr::GET(
#     url = url
#   )
#
#   if(!res$status_code == 200) {
#     next()
#   }
#
#   readr::write_file(x = res$content, file = file, append = FALSE)
# }
