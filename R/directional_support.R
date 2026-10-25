# Reconstruct continuous directional exposure support.
#
# Initial implementation for controlled synthetic tests.
# Mirrors the length-based method in fireexposuR 1.2.0.
#
# Inputs:
#   exposure  - terra SpatRaster, values in [0, 1]
#   transects - terra SpatVector of lines from fire_exp_dir()
#   thresh_exp - high-exposure threshold
#   thresh_viable - directional viability threshold
#
# Output:
#   Data frame with directional support and decision margins.

directional_support <- function(
    exposure,
    transects,
    thresh_exp = 0.60,
    thresh_viable = 0.80) {

  stopifnot(
    inherits(exposure, "SpatRaster"),
    inherits(transects, "SpatVector"),
    terra::same.crs(exposure, transects),
    all(c("deg", "seg") %in% names(transects)),
    thresh_exp >= 0,
    thresh_exp <= 1,
    thresh_viable >= 0,
    thresh_viable <= 1
  )

  # Preserve one record per original segment.
  original <- as.data.frame(transects)

  original$key <- paste(
    original$deg,
    original$seg,
    sep = "_"
  )

  stopifnot(!anyDuplicated(original$key))

  original$length_m <- terra::perim(transects)

  # Match the high-exposure classification method.
  rcm <- matrix(
    c(0, thresh_exp, NA,
      thresh_exp, 1, 1),
    ncol = 3,
    byrow = TRUE
  )

  high <- terra::classify(
    exposure,
    rcm,
    include.lowest = TRUE
  )

  high_poly <- terra::as.polygons(high)

  # Default to zero intersection length.
  original$high_length_m <- 0

  if (length(high_poly) > 0) {

    intersections <- terra::crop(
      transects,
      high_poly
    )

    if (length(intersections) > 0) {

      intersect_data <- as.data.frame(intersections)

      intersect_data$key <- paste(
        intersect_data$deg,
        intersect_data$seg,
        sep = "_"
      )

      intersect_data$high_length_m <-
        terra::perim(intersections)

      lengths <- aggregate(
        high_length_m ~ key,
        data = intersect_data,
        FUN = sum
      )

      idx <- match(original$key, lengths$key)

      matched <- !is.na(idx)

      original$high_length_m[matched] <-
        lengths$high_length_m[idx[matched]]
    }
  }

  original$high_fraction <-
    original$high_length_m / original$length_m

  original$decision_margin <-
    original$high_fraction - thresh_viable

  original$reconstructed_viable <- as.integer(
    original$high_fraction >= thresh_viable
  )

  original[, c(
    "deg",
    "seg",
    "length_m",
    "high_length_m",
    "high_fraction",
    "decision_margin",
    "reconstructed_viable"
  )]
}
