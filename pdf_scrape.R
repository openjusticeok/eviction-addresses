library(ojodb)

ojo_connect()

data <- ojo_table("ojo_civ_cases") |>
  filter(court == "TULSA",
         issue == "EVICTION",
         !disp_case == "OPEN") |>
  collect()

subset <- data |>
  slice_head(n = 100)

