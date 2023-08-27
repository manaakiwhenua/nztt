# User-exposed NZ soil texture triangle data

# nztt <- read.csv('./data-raw/nztt.csv')
nztt <- read.csv('./data-raw/nztt_nudge.csv')

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

