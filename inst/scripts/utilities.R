# library(ojodb)
#
# eviction_cases <- ojo_civ_cases(
#   districts = "TULSA",
#   case_types = "SC",
#   file_years = 2020:year(today())
# ) |>
#   filter(str_detect(description, "FORCIBLE ENTRY"))
#
# feds_minutes <- ojo_tbl("minute") |>
#   filter(code == "FEDS")
#
# eviction_cases |>
#   left_join(feds_minutes, by = c("id" = "case_id"))


get_document_num <- function(casenum) {
  url <- str_c("https://www.oscn.net/dockets/GetCaseInformation.aspx?db=tulsa&number=", casenum)

  table <- url %>%
    session() %>%
    html_element(".docketlist") %>%
    html_table() %>%
    filter(Code == "FEDS") %>%
    select(Description)

  if (nrow(table) == 0) {
    return(NA)
  }

  table %>%
    slice(1) %>%
    str_match("#([0-9]+)") %>%
    pluck(2) %>%
    return()
}

download_document <- function(url, name, dir) {
  file_name <- str_c(name, ".pdf")
  path <- str_c(dir, file_name, sep = "/")
  download.file(url = url, destfile = path, quiet = T)
  return()
}

process_pdf <- function(file) {
  res <- try(dai_sync(file, loc = "US"))
  text <- try(text_from_dai_response(res))
  return(text)
}

query_data <- function(sample_size = 250) {
  ojo_connect()
  data <- ojo_table("oscn_eviction_address") %>%
    filter(court == "TULSA", !is.na(addr_method)) %>%
    collect() %>%
    slice_sample(n = sample_size)
  ojo_disconnect_all()
  return(data)
}

transform_query <- function(data) {
  data %>%
    mutate(
      doc_num = future_map_chr(casenum, get_document_num, .progress = T),
      doc_url = str_c(
        "https://www.oscn.net/dockets/GetDocument.aspx?ct=tulsa&bc=",
        doc_num,
        "&cn=",
        casenum,
        "&fmt=pdf"
      ),
      doc_name = str_c(casenum, str_to_lower(court), doc_num, sep = "_")
    )
}

download_documents <- function(data, download_dir = "./data/validation1") {
  data %>%
    select(doc_url, doc_name) %>%
    drop_na() %>%
    future_pmap(~download_document(.x, .y, dir = download_dir), .progress = T)
}

process_dai <- function(data, download_dir = "./data/validation1") {
  dir_ls(download_dir) %>%
    as_tibble() %>%
    rename(file = value) %>%
    mutate(processed = future_map_chr(file, process_pdf, .progress = T, .options = furrr_options(seed = T, globals = c(".auth"), packages = c("daiR"))))
}

process_nlp <- function(data) {
  data %>%
    mutate(entity = map(processed, ~gl_nlp(., nlp_type = "analyzeEntities", language = "en") %>%
                          pluck("entities") %>%
                          pluck(1)))
}

transform_post_nlp <- function(data) {
  data %>%
    unnest(cols = entity) %>%
    filter(type == "ADDRESS") %>%
    select(file, processed, name, type, locality, street_number,
           street_name, broad_region, postal_code, number) %>%
    filter(!is.na(street_name)) %>%
    select(-c(processed, type)) %>%
    mutate(address = str_c(street_number, street_name, locality, broad_region, str_replace_na(postal_code, replacement = ""), sep = " ") %>% str_squish())
}

process_usps <- function(data) {
  data %>%
    mutate(street = str_c(street_number, street_name, sep = " ")) %>%
    select(street, locality, broad_region) %>%
    distinct() %>%
    mutate(results = pmap(., ~validate_address_usps(..1, ..2, ..3, username = Sys.getenv("USPS_USER")) %>%
                            replace(is.na(.), as.character(NA)) %>%
                            mutate(across(everything(), as.character)) %>%
                            as_tibble() %>%
                            drop_na() %>%
                            distinct())) %>%
    unnest(cols = results)
}

# validate_data <- function(data) {
#
# }
