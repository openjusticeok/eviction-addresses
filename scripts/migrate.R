library(ojodb)

old_addresses <- ojo_tbl("old_db_temp", schema = "eviction_addresses")
case_table <- ojo_tbl("case")

old_addresses |>
  select(court, casenum) |>
  inner_join(case_table, by = c("court" = "district", "casenum" = "case_number"))

old_casenums <- old_addresses |>
  select(casenum, court) |>
  collect()

test <- old_casenums |>
  mutate(test = str_match(casenum, "(\\w*-\\d*-)0*(.*)"),
         new_casenum = str_c(test[,2], test[,3])) |>
  inner_join(case_table, by = c("new_casenum" = "case_number", "court" = "district"), copy = T)


str_match("SC-2019-00001", "\\w*-\\d*-0*(.*)") |>
  pluck(2) |>
  as.integer()
