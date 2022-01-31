#!/usr/local/bin/Rscript

library(ojo)
library(magick)
library(glue)
library(ggmap)
library(googlesheets4)

windex <- function(x) {
  str_remove_all({{x}}, " INC| CO(?=($| ))|LLC|LP|LIMITED PARTNERSHIP|QLA|[[:punct:]]|THE | PHASE.{1,30}$|COMPANY|C\\/O.{1,30}| (AT|OF)(?= )| AND|II|DBA.*") %>%
    str_replace_all("APT([[:alpha:]]|)|APARTMENT([[:alpha:]]|)$|APARTMENT HOMES", "APARTMENTS") %>%
    str_replace("MHC|MHP|MOBILE HOME.*", "MOBILE HOMES") %>%
    str_remove_all(" [[:alpha:]]$") %>%
    str_squish %>%
    str_replace("HOUSING AUTH.*", "TULSA HOUSING AUTHORITY") %>%
    str_replace("MENTAL HEALTH AS.*", "MENTAL HEALTH ASSOCIATION") %>%
    str_replace("CHAT.*68.*", "CHATEAU 68 APARTMENTS") %>%
    str_replace(".*AVONDALE.*", "JA AVONDALE")
}

ext_addr <- function(x) {
  ifelse(!is.na(str_extract(x, "\\d{2,8}.{3,25}(AV|BLVD|ST|PL|CT|PI|DR|TER|RD)")),
         str_extract(x, "\\d{2,8}.{3,25}(AV|BLVD|ST|PL|CT|PI|DR|TER|RD)") %>%
           str_squish() %>%
           str_replace("PI$", "PL") %>%
           str_replace_all("[^[[:alnum:]]\\s]", " ") %>%
           str_remove(" UNIT.*$") %>%
           str_replace(" AVE$", " AV") %>%
           str_replace(" STREET$", " ST") %>%
           str_remove("(?<=\\d{1,4})(TH|ST|RD|ND)") %>%
           str_replace_all("(?<=\\d)(?=[[:alpha:]])", " ") %>%
           str_replace_all("(?<=[[:alpha:]])(?=\\d)", " ") %>%
           str_squish,
         str_extract(x, "\\d{2,8}.{3,25}(?=TULSA|BROKEN ARROW|JENKS|OWASSO|BIXBY|COLLINSVILLE|SAPULPA|SAND SPRINGS|GLENPOOL)") %>%
           str_squish() %>%
           str_replace("PI$", "PL") %>%
           str_replace_all("[^[[:alnum:]]\\s]", " ") %>%
           str_remove(" UNIT.*$") %>%
           str_replace(" AVE$", " AV") %>%
           str_replace(" STREET$", " ST") %>%
           str_remove("(?<=\\d{1,4})(TH|ST|RD|ND)") %>%
           str_replace_all("(?<=\\d)(?=[[:alpha:]])", " ") %>%
           str_replace_all("(?<=[[:alpha:]])(?=\\d)", " ") %>%
           str_squish)
}
ext_zip <- function(x) {
  str_extract(x, "74\\d{3}") %>%
    str_remove_all("[[:punct:]]") %>%
    str_squish()
}
ext_city <- function(x) {
  str_extract(x, "TULSA|BROKEN ARROW|JENKS|OWASSO|BIXBY|COLLINSVILLE|SAPULPA|SAND SPRINGS|GLENPOOL")
}

ocr_crop <- function(x) {
  pdf %>%
    image_crop(x) %>%
    image_ocr() %>%
    str_to_upper() %>%
    str_remove_all("[[:punct:]]")
}

ojo_geocode <- function(x) {
  for (i in 1:nrow(x)) {
    result <- geocode(paste(x$addr[i],
                            x$city[i], "OK"),
                      output = "more", source = "google")

    if (ncol(result) > 2) {
      x$lon[i] <- as.numeric(result[1])
      x$lat[i] <- as.numeric(result[2])
      x$addr_google[i] <- str_to_upper(result[5]) %>%
        as.character
    }
  }
  return(x)
}

##### Get evictions we haven't geocoded yet ####
connect_ojo()

d <- dbGetQuery(ojo_db,
                "SELECT court, casenum, file_date, iss_plaint FROM oscn_civ_disps
                WHERE court = 'TULSA'
                AND file_date > '2019-01-01'
                AND casetype = 'SC'
                AND iss_desc LIKE 'FORC%'
                AND casenum NOT IN (SELECT casenum FROM oscn_eviction_address
                WHERE court = 'TULSA')") %>%
  group_by(casenum) %>%
  slice(1) %>%
  ungroup %>%
  mutate(
    plaint_clean = windex(iss_plaint))

apt_master <- dbReadTable(ojo_db, "tul_apt_master")

disconnect_ojo()

#### Geocode apartments by name by joining with tul_apt_master table ####
apts <- d %>%
  left_join(apt_master) %>%
  filter(!is.na(lon)) %>%
  select(court, casenum, file_date, iss_plaint, plaint_clean, addr, city, lon, lat) %>%
  mutate(addr_method = "APARTMENT NAME")

connect_ojo()
dbWriteTable(ojo_db, "oscn_eviction_address", apts, append = TRUE, row.names = FALSE)
disconnect_ojo()

##### Get new evictions manually extracted and entered in Google sheets ####
sheets_deauth()
ev19 <- read_sheet("1vTOOOKJ-d-22uaJ9VD9SLh5-JOOCxPNvKkBA5ysz0os")

connect_ojo()
been_got <- dbGetQuery(ojo_db, "SELECT *
                                FROM oscn_eviction_address
                                WHERE addr_method LIKE 'MANUAL%'
                                AND court = 'TULSA'")
disconnect_ojo()

new_addr <- ev19 %>%
  filter(!casenum %in% been_got$casenum) %>%
  filter(!is.na(addr) | !is.na(notes)) %>%
  mutate(addr = str_to_upper(addr) %>%
           str_remove(",.*") %>%
           str_remove_all("[[:punct:]]"),
         city = str_to_upper(city),
         plaint_clean = windex(iss_plaint)) %>%
  select(court, casenum, file_date, iss_plaint, plaint_clean, addr, city, notes)

register_google("AIzaSyAfbWTG0O9TwzZ99Nw0oz_9NCqGMpgPuD4")

if (nrow(new_addr) > 0) {
  new_addr <- new_addr %>%
    filter(!is.na(city), !is.na(addr)) %>%
    mutate(addr = if_else(is.na(addr), "", addr)) %>%
    ojo_geocode() %>%
    mutate(addr_method = paste0("MANUAL (RESTORE HOPE ", Sys.Date(), ")"),
           lon = ifelse(addr == "" | is.na(addr), NA, lon),
           lat = ifelse(addr == "" | is.na(addr), NA, lat)) %>%
    select(-notes)

  connect_ojo()
  dbxUpsert(ojo_db, "oscn_eviction_address", new_addr, where_cols = c("casenum"))
  disconnect_ojo()
}

