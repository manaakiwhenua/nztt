# Example Wairau data
wairau <- read.csv('./data-raw/wairau.csv')

usethis::use_data(wairau, overwrite = TRUE)

# Standard colours for NZ texture classes
# from: https://www.landis.org.uk/data/images/texture%20triangle%20and%20peat.jpg
#
# This is the original data, with my notes:
#
# colours_texture <- data.frame(
#   rbind(
#     c("Clay", "#80acdd"),
#     c("Sandy Clay", "#9eacb1"), # Not in NZTT: should be Loamy Clay
#     c("Silty Clay", "#6bc4a6"),
#     c("Sandy Clay Loam", "#dfe396"),
#     c("Clay Loam", "#c2d2ec"),
#     c("Silty Clay Loam", "#8baa67"), # Use this colour for Silt? Just because darker green
#     c("Sand", "#cd9a96"),
#     c("Loamy Sand", "#dba780"),
#     c("Sandy Loam", "#f2d088"),
#     c("Sandy Silt Loam", "#f0e999"), # Not in NZTT: should be Loamy Silt
#     c("Silt Loam", "#a7bd75") # Not in NZTT - should be Silt, but use this colour for Silt Loam
#   )
# )

colours_texture <- data.frame(
  rbind(
    c("Clay", "#80acdd"),
    c("Loamy Clay", "#9eacb1"),
    c("Silty Clay", "#c2d2ec"),
    c("Sandy Clay Loam", "#dfe396"),
    c("Clay Loam", "#f0e999"),
    c("Silt Loam", "#6bc4a6"),
    c("Sand", "#cd9a96"),
    c("Sandy Loam", "#f2d088"),
    c("Loamy Sand", "#dba780"),
    c("Loamy Silt", "#a7bd75"), # Not in NZTT: should be Loamy Silt
    c("Silt", "#8baa67") # Not in NZTT - should be Silt, but use this colour for Silt Loam
  )
)
names(colours_texture) <- c("name", "colour")

palette_nztt <- colours_texture$colour
names(palette_nztt) <- colours_texture$name

usethis::use_data(palette_nztt, overwrite = TRUE)

# User-exposed NZ soil texture triangle data

# nztt <- read.csv('./data-raw/nztt.csv')
nztt <- read.csv('./data-raw/nztt_nudge.csv')
nztt$X <- NULL

nztt <- dplyr::left_join(nztt, colours_texture)

usethis::use_data(nztt, overwrite = TRUE)



# Internal sf version of NZTT data above
tt_coords_tern <- as.matrix(nztt[,1:3])
tt_coords_cart <- t(apply(tt_coords_tern, 1, Ternary::TernaryToXY))
tt_coords_cart <- data.frame(
  name = nztt$name,
  tt_coords_cart
)

sf_tt <- plyr::dlply(
  tt_coords_cart,
  "name",
  function(x)
    sf::st_polygon(
      list(
        as.matrix(
          rbind(
            x[,-1],
            x[1,-1]
          )
        )
      )
    )
)

.nztt_sf <- sf::st_as_sf(
  data.frame(
    name = names(sf_tt),
    geom = sf::st_as_sfc(sf_tt)
  )
)

.nztt_sf <- merge(.nztt_sf, nztt[, c("name", "code")])

.nztt_sf <- unique(.nztt_sf)

usethis::use_data(.nztt_sf, internal = TRUE, overwrite = TRUE)

