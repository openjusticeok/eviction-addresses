library(googleCloudStorageR)
library(googleCloudRunner)
library(tidyverse)

# Authenticate with Google Cloud Storage
gcs_auth(json_file = "eviction-addresses-service-account.json")

# Get a list of all the documents in the bucket
docs <- googleCloudStorageR::gcs_list_objects("eviction-addresses") |>
  as_tibble()

# Filter for documents that are too small to be valid PDFs
empties <- docs |>
  mutate(size_num = str_extract(size, "\\d+\\.\\d+") |>
           as.numeric()) |>
  filter(size_num == 1.2, str_detect(size, "Kb"))

# Delete them
walk(
  empties$name,
  function(x) {
    gcs_delete_object(x, bucket = "eviction-addresses")
  }
)

# Get a list of all the documents in the database
records <- ojo_tbl("document", "eviction_addresses") |>
  filter(!is.na(internal_link)) |>
  ojo_collect()

# Find the documents that are in the database but not in the bucket
deads <- anti_join(
  records,
  docs,
  by = c("id" = "name")
)

# Delete their internal link from the database since it is broken
walk(
  deads$id,
  function(x) {
    q <- glue_sql(
      .con = ojo_connect(),
      'UPDATE "eviction_addresses"."document" SET "internal_link" = NULL WHERE "id" = {x};'
    )
    dbExecute(ojo_connect(), q)
  }
)
