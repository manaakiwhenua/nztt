#' tern_to_cart
#'
#' @title Converts Ternary to Cartesian Coordinates
#'
#' @importFrom Ternary TernaryToXY
#' @importFrom sf st_as_sf
#'
#' @author Pierre Roudier
#'
#' @noRd
#'
tern_to_cart.numeric <- function(x) {

  coords <- TernaryToXY(x)

  pt <- st_as_sf(
    data.frame(
      x = coords[1],
      y = coords[2]
    ),
    coords = c("x", "y")
  )

  return(pt)
}

tern_to_cart.data.frame <- function(x) {
  res <- apply(
    x,
    1,
    tern_to_cart.numeric
  )

  res <- do.call(rbind, res)

  return(res)
}

intersect_pt_with_triangle <- function(pt, tri) {
  # For each point, process the intersection
  res_sf <- suppressWarnings(st_intersection(pt, tri))

  # If the point somehow falls between the two polygons, we affect it to
  # the closest one
  if (nrow(res_sf) == 0) {
    idx_closest <- st_nearest_feature(pt, tri)
    res_sf <- tri[idx_closest,]
    res_sf$.id <- pt$.id
  }

  return(res_sf)
}

#' texture_class
#'
#' @title Get Texture Class from Texture Data
#'
#' @param clay .
#' @param sand .
#' @param silt .
#' @param triangle Which texture triangle to use. Currently implemented are the NZ texture triangle (option "nz", default) or the S-Map texture triangle (option "smap").
#' @param rescale_psd Does the PSD data needs to be rescaled from [0, 1] to [0, 100]? Defaults to `FALSE`.
#'
#' @returns description .
#'
#' @author Pierre Roudier
#'
#' @importFrom Ternary TernaryToXY
#' @importFrom sf st_intersection st_drop_geometry st_nearest_feature
#' @include datasets.R
#' @export
#'
#' @examples
#'
#' texture_class(clay = 40, silt = 14, sand = 46)
#' texture_class(clay = 40, silt = 14, sand = 46, triangle = "smap")
#'
#' # Load example data
#' data(wairau)
#'
#' # Calculate texture classes
#' tx <- texture_class(clay = wairau$clay, sand = wairau$sand, silt = wairau$silt)
#' print(tx)
#'
#' # Check the results
#' cbind(tx$name, wairau$name)
#'
#' # Example using the tidyverse verbs
#'
#' library(dplyr)
#' data(wairau)
#' wairau %>%
#'   select(id, clay, sand, silt) %>%
#'   mutate(
#'     texture = texture_class(clay = clay, sand = sand, silt = silt)$name
#'   )
#'
texture_class <- function(clay, sand, silt, triangle = "nz", rescale_psd = FALSE) {

  if (length(clay) != length(sand) | length(clay) != length(silt) | length(silt) != length(sand)) {
    stop("Make sure that clay, sand, and silt have the same length.",call. = FALSE)
  }

  # Check if triangle option is one of the 2 available
  triangle <- tolower(triangle)
  if (!triangle %in% c("nz", "smap")) {
    stop("Texture triangle should be one of 'nz' or 'smap'.", call. = FALSE)
  }

  # if (clay[1] <= 1 & sand[1] <= 1 & silt[1] <= 1) {
  if (rescale_psd) {

    clay <- clay * 100
    sand <- sand * 100
    silt <- silt * 100

    message("Rescaling sand, silt, clay data between 0 and 100")
  }

  # Automatic limitation of PSD data accuracy to get around the issue of points on
  # polygon boundaries
  .nztt.digits <- 1
  clay <- round(clay, digits = .nztt.digits)
  sand <- round(sand, digits = .nztt.digits)
  silt <- round(silt, digits = .nztt.digits)

  t_df <- data.frame(clay = clay, sand = sand, silt = silt)

  # Get Cartesian coordinates of the texture data
  t_sf <- tern_to_cart.data.frame(t_df)

  # Add index to re-order rows
  t_sf$.id <- 1:nrow(t_sf)

  # compute intersection with the texture triangle in cartesian space
  if (triangle == "nz") {
    sf_texture_triangle <- .nztt_sf
  } else if (triangle == "smap") {
    sf_texture_triangle <- .smaptt_sf
  }

  # For each point, we need to process the intersection with the texture triangle
  res_sf <- lapply(
    1:nrow(t_sf),
    function(i) {
      res <- intersect_pt_with_triangle(
        pt = t_sf[i,],
        tri = sf_texture_triangle
      )
    }
  )

  res_sf <- do.call(rbind, res_sf)

  # Re-arrange based on initial row orders
  res_sf <- res_sf[order(res_sf$.id),]

  # Remove spatial info and just keep the two relevant columns
  res <- st_drop_geometry(res_sf[, c("name", "code")])

  return(res)

}
