# D01: Recover and preserve the original Westwood Hills study window.
#
# Geographic references come from the earlier
# WFCC_2026/EXP100/fireexposuR_learning/02_halifax_exposure.R
#
# This is an approximately 20 x 20 km square centred on
# Upper Tantallon, with Westwood Hills as the assessment point.

library(terra)

fuel_path <- "data/raw/fbp-2026-candidate/fss.tiff"

output_dir <- "data/processed/study-window"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

fuel <- rast(fuel_path)

make_point <- function(lon, lat) {
  vect(
    data.frame(lon = lon, lat = lat),
    geom = c("lon", "lat"),
    crs = "EPSG:4326"
  )
}

tantallon <- make_point(-63.877807, 44.687808)
westwood <- make_point(-63.873570, 44.717410)

tantallon_proj <- project(tantallon, crs(fuel))
westwood_proj <- project(westwood, crs(fuel))

# Match the original script's square bounding extent.
study_extent <- ext(buffer(tantallon_proj, width = 10000))

study_polygon <- as.polygons(
  study_extent,
  crs = crs(fuel)
)

fuel_local <- crop(fuel, study_extent)

# Save the original geometric study boundary and assessment points.
writeVector(
  study_polygon,
  file.path(output_dir, "study_boundary.gpkg"),
  overwrite = TRUE
)

tantallon_proj$location <- "Upper Tantallon"
westwood_proj$location <- "Westwood Hills"

reference_points <- rbind(
  tantallon_proj,
  westwood_proj
)

writeVector(
  reference_points,
  file.path(output_dir, "reference_points.gpkg"),
  overwrite = TRUE
)

writeRaster(
  fuel_local,
  file.path(output_dir, "fbp_2026_candidate_100m.tif"),
  overwrite = TRUE
)

# Verify output geometry.
stopifnot(
  ncell(fuel_local) == 40000,
  nrow(fuel_local) == 200,
  ncol(fuel_local) == 200,
  nrow(reference_points) == 2,
  relate(westwood_proj, study_polygon, "intersects")
)

cat("\n=== D01 study-window export ===\n")
cat("CRS:", crs(fuel_local, proj = TRUE), "\n")

cat("\nStudy boundary:\n")
print(study_extent)

cat("\nRaster-aligned extent:\n")
print(ext(fuel_local))

cat("\nReference points:\n")
print(crds(reference_points))

cat("\nOutputs:\n")
print(list.files(output_dir, full.names = TRUE))

cat("\nD01 study-window export: PASSED\n")
