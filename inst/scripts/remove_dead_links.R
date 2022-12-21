library(googleCloudStorageR)
library(googleCloudRunner)
library(ojodb)

gcs_auth()

docs <- gcs_list_objects(bucket = "eviction-addresses") |>
  as_tibble()

records <- ojo_tbl("document", "eviction_addresses") |>
  filter(!is.na(internal_link)) |>
  collect()

deads <- anti_join(
  records,
  docs,
  by = c("id" = "name")
)

walk(
  deads$id,
  function(x) {
    print(x)
    q <- glue_sql(
      .con = ojodb,
      'UPDATE "eviction_addresses"."document" SET "internal_link" = NULL WHERE "id" = {x};'
    )
    dbExecute(ojodb, q)
  }
)
