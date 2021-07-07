setwd("~/Documents/okpolicy/google-ocr-demo/")
set.seed(1234)

library(ojodb)
library(daiR)
library(googleCloudStorageR)
library(googleLanguageR)
library(rvest)
library(fs)
library(rusps)
library(XML)
library(furrr)

source("./R/utilities.R")

plan(multisession(workers = availableCores() - 1))

project_id <- daiR::get_project_id()
# gcs_create_bucket("ocr-demo-bucket-123456789", project_id, location = "US")
gcs_global_bucket("ocr-demo-bucket-123456789")
# gcs_upload_set_limit(upload_limit = 20000000L)


# https://www.oscn.net/dockets/GetCaseInformation.aspx?db=tulsa&number=SC-2012-5602
# https://www.oscn.net/dockets/GetDocument.aspx?ct=tulsa&bc=1017889510&cn=SC-2012-5602&fmt=pdf


###### Initial Tests

ojo_connect()
evictions <- ojo_table("ojo_civ_cases") %>%
  filter(
    court == "TULSA",
    file_year >= 2010,
    issue == "EVICTION"
  ) %>%
  collect() %>%
  sample_n(100)
ojo_disconnect_all()

evictions <- evictions %>%
  mutate(
    doc_num = map_chr(casenum, get_document_num),
    doc_url = str_c(
      "https://www.oscn.net/dockets/GetDocument.aspx?ct=tulsa&bc=",
      doc_num,
      "&cn=",
      casenum,
      "&fmt=pdf"
    ),
    doc_name = str_c(casenum, str_to_lower(court), doc_num, sep = "_")
  )

evictions %>%
  select(doc_url, doc_name) %>%
  drop_na() %>%
  pmap(~download_document(.x, .y, dir = "./data"))

output <- dir_ls("data") %>%
  as_tibble() %>%
  rename(file = value) %>%
  mutate(processed = map_chr(file, process_pdf))

output <- output %>%
  mutate(entity = map(processed, ~gl_nlp(., nlp_type = "analyzeEntities", language = "en") %>%
                        pluck("entities") %>%
                        pluck(1)))

parsed <- output %>%
  unnest(cols = entity) %>%
  filter(type == "ADDRESS") %>%
  select(file, processed, name, type, street_name:postal_code) %>%
  filter(!is.na(street_name))

parsed <- parsed %>%
  select(-c(processed, type)) %>%
  mutate(address = str_c(street_number, street_name, locality, broad_region, str_replace_na(postal_code, replacement = ""), sep = " ") %>% str_squish())

usps <- parsed %>%
  mutate(street = str_c(street_number, street_name, sep = " ")) %>%
  select(street, locality, broad_region) %>%
  distinct() %>%
  mutate(results = pmap(., ~validate_address_usps(..1, ..2, ..3, username = Sys.getenv("USPS_USER")) %>%
                          replace(is.na(.), as.character(NA)) %>%
                          mutate(across(everything(), as.character)) %>%
                          as_tibble() %>%
                          drop_na() %>%
                          distinct()))

# gcs_list_objects()
# dir_ls("data") %>%
#   map(~gcs_upload(.x, name = path_file(.x)))
#
# res <- gcs_list_objects() %>%
#   select(name) %>%
#   pluck(1) %>%
#   dai_async(dest_folder = "output", loc = "US")


# response <- dai_sync("data/1017823909-20120426-103711-.pdf", loc = "US")
# text <- text_from_dai_response(response)
#
# res <- evictions %>%
#   select(plaintiff) %>%
#   mutate(entity = map(plaintiff, ~gl_nlp(., nlp_type = "analyzeEntities", language = "en") %>%
#                         pluck("entities") %>% pluck(1)))


######### Validation Testing

ojo_connect()
validation_data <- ojo_table("oscn_eviction_address") %>% 
  filter(court == "TULSA", !is.na(addr_method)) %>%
  collect() %>%
  slice_sample(n = 250)
ojo_disconnect_all()

validation_data <- validation_data %>%
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

validation_data %>%
  select(doc_url, doc_name) %>%
  drop_na() %>%
  future_pmap(~download_document(.x, .y, dir = "./data/validation1/"), .progress = T)

validation_output <- dir_ls("data/validation1") %>%
  as_tibble() %>%
  rename(file = value) %>%
  mutate(processed = future_map_chr(file, process_pdf, .progress = T, .options = furrr_options(seed = T, globals = c(".auth"), packages = c("daiR"))))

validation_output <- validation_output %>%
  mutate(entity = map(processed, ~gl_nlp(., nlp_type = "analyzeEntities", language = "en") %>%
                        pluck("entities") %>%
                        pluck(1)))

validation_parsed <- validation_output %>%
  unnest(cols = entity) %>%
  filter(type == "ADDRESS") %>%
  select(file, processed, name, type, street_number:postal_code) %>%
  filter(!is.na(street_name))

validation_parsed <- validation_parsed %>%
  select(-c(processed, type)) %>%
  mutate(address = str_c(street_number, street_name, locality, broad_region, str_replace_na(postal_code, replacement = ""), sep = " ") %>% str_squish())

validation_usps <- validation_parsed %>%
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

