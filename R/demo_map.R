library(ojodb)
library(sf)
library(tmap)
library(spData)

ok <- us_states |>
  filter(NAME == "Oklahoma")

proj4 <- st_crs(ok)$proj4string

data <- ojo_tbl("address", "eviction_addresses") |>
  select(case, lat, lon, geo_accuracy) |>
  collect()

data_points <- data |>
  drop_na() |>
  st_as_sf(coords = c('lon', 'lat'), crs = proj4)

tm_shape(ok) +
  tm_polygons('#f0f0f0f0', border.alpha = 0.2) +
  tm_shape(data_points) +
  tm_dots(alpha = 0.2)





