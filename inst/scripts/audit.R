library(ojoverse)

ojo_tbl("address", schema = "eviction_addresses") |>
# Add some filters to get a representative sample over time, maybe over geo?
  left_join(
    ojo_tbl(
      "document",
      schema = "eviction_addresses"
    ),
    by = c("case")
  ) |>
  select(internal_link) |>
  head(10) |>
  ojo_collect() |>
  clipr::write_clip()
