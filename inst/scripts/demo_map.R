library(ojodb)
library(sf)
library(tmap)
library(tigris)
library(tidycensus)

tmap_mode("plot")

ok_counties <- counties("Oklahoma", cb = TRUE)
tulsa_county <- ok_counties |>
  filter(NAME == "Tulsa")

ok <- states() |>
  filter(NAME == "Oklahoma")

tps <- school_districts(state = "OK") |>
  filter(
    str_detect(NAME, "Tulsa")
  )

blockgroups <- block_groups(state = "OK", county = "Tulsa")

proj4 <- st_crs(ok)$proj4string

data <- ojo_tbl("address", "eviction_addresses") |>
  select(case, lat, lon, geo_accuracy, geo_accuracy_type) |>
  left_join(ojo_tbl("case") |>
              select(id, district, date_filed), by = c("case" = "id")) |>
  collect()

data_points <- data |>
  drop_na() |>
  st_as_sf(coords = c('lon', 'lat'), crs = proj4)

tm_shape(ok) +
  tm_polygons('#f0f0f0f0', border.alpha = 0.2) +
  tm_shape(data_points |>
             filter(geo_accuracy >= 0.9)) +
  tm_dots(alpha = 0.2)

tmap_mode("view")
tm_shape(tulsa_county) +
  tm_basemap("Stamen.Watercolor") +
  tm_polygons('#f0f0f0f0', border.alpha = 0.2, alpha = 0) +
  tm_shape(blockgroups) +
  tm_polygons('#f0f0f0f0', border.alpha = 1, alpha = 0.2) +
  tm_shape(data_points |>
             filter(geo_accuracy >= 0.9)) +
  tm_dots(alpha = 0.4, col = "lightblue")


