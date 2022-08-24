library(pyMTurkR)
library(tidyverse)
library(uuid)

Sys.setenv(AWS_ACCESS_KEY_ID = "")
Sys.setenv(AWS_SECRET_ACCESS_KEY = "")

options(
  pyMTurkR.sandbox = T,
  pyMTurkR.verbose = T
)

layout_id <- "3KCFCGTK7V2ZMAIT83VZJL9HER9BP5"
# hit_type_id <- "3C7PNR93YHZCDH4797QDJNZZYHH4EX"
#
# hits <- ListHITs() |>
#   as_tibble()
#
# reviewable_hits <- pyMTurkR::reviewable() |>
#   as_tibble()
#
# test <- reviewable_hits |>
#   mutate(
#     hit_details = map_df(HITId, gethit)
#   )


ea_hit_type <- CreateHITType(
  title = "eviction-address-transcription",
  description = "Find and transcribe the DEFENDENT'S address from a court document pdf",
  reward = "0.15",
  duration = pyMTurkR::seconds(minutes = 10),
  keywords = "address, text, transcribe, entry, data",
  auto.approval.delay = pyMTurkR::seconds(days = 3),
)

ea_hit_type_id <- ea_hit_type$HITTypeId
ea_hit_type_status <- ea_hit_type$Valid

# GenerateAssignmentReviewPolicy
# GenerateHITReviewPolicy

ea_hit_layout <- read_file("inst/mturk/layout.xml")

ea_sample_hit <- CreateHITWithHITType(
  hit.type = ea_hit_type_id,
  question = ea_hit_layout,
  # hitlayoutid = layout_id,
  # hitlayoutparameters = list(
  #   list(
  #     Name = "url",
  #     Value = "https://google.com"
  #   )
  # ),
  expiration = pyMTurkR::seconds(days = 1),
  assignments = "3",
  unique.request.token = uuid::UUIDgenerate(output = "string")
)

gethit(hit = ea_sample_hit$HITId)

ea_hit_status <- HITStatus(ea_sample_hit$HITId)

ea_assignment <- ListAssignmentsForHIT(hit = ea_sample_hit$HITId, get.answers = T)

