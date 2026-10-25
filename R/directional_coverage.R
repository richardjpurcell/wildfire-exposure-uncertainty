# Directional evidence coverage.
#
# Measures the proportion of each directional segment
# intersecting nonmissing raster cells.
#
# Coverage is independent of exposure thresholds and
# directional viability classifications.

directional_coverage <- function(exposure, transects) {

  stopifnot(
    inherits(exposure, "SpatRaster"),
    inherits(transects, "SpatVector"),
    terra::same.crs(exposure, transects),
    terra::nlyr(exposure) == 1,
    all(c("deg", "seg") %in% names(transects))
  )

  result <- as.data.frame(transects)

  result$key <- paste(
    result$deg,
    result$seg,
    sep = "_"
  )

  stopifnot(!anyDuplicated(result$key))

  result$total_length_m <- terra::perim(transects)
  result$observed_length_m <- 0

  # Raster cells with available evidence.
  observed <- terra::ifel(
    !is.na(exposure),
    1,
    NA
  )

  observed_polygons <- terra::as.polygons(observed)

  if (length(observed_polygons) > 0) {

    intersections <- terra::crop(
      transects,
      observed_polygons
    )

    if (length(intersections) > 0) {

      parts <- as.data.frame(intersections)

      parts$key <- paste(
        parts$deg,
        parts$seg,
        sep = "_"
      )

      parts$length_m <- terra::perim(intersections)

      lengths <- aggregate(
        length_m ~ key,
        data = parts,
        FUN = sum
      )

      indices <- match(result$key, lengths$key)
      matched <- !is.na(indices)

      result$observed_length_m[matched] <-
        lengths$length_m[indices[matched]]
    }
  }

  result$coverage_fraction <-
    result$observed_length_m /
    result$total_length_m

  result[, c(
    "deg",
    "seg",
    "total_length_m",
    "observed_length_m",
    "coverage_fraction"
  )]
}
