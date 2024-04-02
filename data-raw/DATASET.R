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

colours_texture_smap <- data.frame(
  rbind(
    c("Clayey", "#80acdd"),
    c("Loamey", "#f0e999"),
    c("Sandy", "#cd9a96"),
    c("Silty", "#8baa67") # Not in NZTT - should be Silt, but use this colour for Silt Loam
  )
)
names(colours_texture_smap) <- c("name", "colour")

palette_smap <- colours_texture_smap$colour
names(palette_smap) <- colours_texture_smap$name

usethis::use_data(palette_smap, overwrite = TRUE)

colours_nzsc <- data.frame(
  rbind(
    c("Allophanic", "#f5a7a0"),
    c("Anthropic", "#ffd994"),
    c("Brown", "#c29954"),
    c("Gley", "#65c1f0"),
    c("Granular", "#ee816d"),
    c("Melanic", "#afafaf"),
    c("Organic", "#6a6e99"),
    c("Oxidic", "#ff4d73"),
    c("Pallic", "#009b76"),
    c("Podzol", "#bd87e5"),
    c("Pumice", "#89cd66"),
    c("Raw", "#fffab3"),
    c("Recent", "#f7dd00"),
    c("Semiarid", "#ffabc7"),
    c("Ultic", "#a59b00")
  )
)
names(colours_nzsc) <- c("name", "colour")

palette_nzsc <- colours_nzsc$colour
names(palette_nzsc) <- colours_nzsc$name

usethis::use_data(palette_nzsc, overwrite = TRUE)

# User-exposed NZ soil texture triangle data

# nztt <- read.csv('./data-raw/nztt.csv')
nztt <- read.csv('./data-raw/nztt_nudge.csv')
nztt$X <- NULL

nztt <- dplyr::left_join(nztt, colours_texture)

usethis::use_data(nztt, overwrite = TRUE)

# S-Map texture triangle

# User-exposed S-Map soil texture triangle data

smaptt <- read.csv('./data-raw/smaptt_nudge.csv')
smaptt$X <- NULL

smaptt <- dplyr::left_join(smaptt, colours_texture_smap)

usethis::use_data(smaptt, overwrite = TRUE)


## INTERNAL VERSIONS FOR CALCULATIONS

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

# Internal sf version of S-Map data above
smaptt_coords_tern <- as.matrix(smaptt[,1:3])
smaptt_coords_cart <- t(apply(smaptt_coords_tern, 1, Ternary::TernaryToXY))
smaptt_coords_cart <- data.frame(
  name = smaptt$name,
  smaptt_coords_cart
)

sf_smaptt <- plyr::dlply(
  smaptt_coords_cart,
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

.smaptt_sf <- sf::st_as_sf(
  data.frame(
    name = names(sf_smaptt),
    geom = sf::st_as_sfc(sf_smaptt)
  )
)

.smaptt_sf <- merge(.smaptt_sf, smaptt[, c("name", "code")])

.smaptt_sf <- unique(.smaptt_sf)

# Export to internal dataset
usethis::use_data(.nztt_sf, .smaptt_sf, internal = TRUE, overwrite = TRUE)
