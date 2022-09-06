# library(ojodb)
# library(furrr)
#
# source("./utilities.R")
#
# set.seed(1234)
#
# plan(multisession, workers = availableCores() - 2)
#
# ojo_connect()
#
# data <- ojo_table("ojo_civ_cases") |>
#   filter(court == "TULSA",
#          issue == "EVICTION",
#          !disp_case == "OPEN") |>
#   collect()
#
# subset <- data |>
#   filter(file_year == 2021) |>
#   slice_sample(n = 1000)
#
# test <- subset |>
#   transform_query()
#
# test |>
#   filter(!is.na(doc_num))
#
#
# test |> select(casenum) |> slice(5)
# url <- str_c("https://www.oscn.net/dockets/GetCaseInformation.aspx?db=tulsa&number=", "SC-2010-00010")
#
# table <- url %>%
#   session() %>%
#   html_element(".docketlist") %>%
#   html_table() %>%
#   filter(Code == "FEDS") %>%
#   select(Description)
#
# table %>%
#   slice(1) %>%
#   str_match("#([0-9]+)") %>%
#   pluck(2)
