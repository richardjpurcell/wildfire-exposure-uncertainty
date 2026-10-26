# D10.6 — Baseline directional assessment at Westwood Hills
#
# Uses the D09 experimental reference exposure raster.
# Viability thresholds are methodological examples,
# not validated safety thresholds.

library(terra)
library(sf)
library(fireexposuR)

cat("\n=== D10.6: BASELINE DIRECTIONAL ASSESSMENT ===\n")

raster_path <- paste0(
  "data/processed/visualization/",
  "d09_reference_exposure_2026_500m.tif"
)

reference_path <- paste0(
  "data/processed/study-window/",
  "reference_points.gpkg"
)

output_path <- paste0(
  "outputs/tables/",
  "d10_baseline_directional_assessment.csv"
)

stopifnot(
  file.exists(raster_path),
  file.exists(reference_path)
)

exposure <- rast(raster_path)

locations <- st_read(reference_path, quiet = TRUE)

selected <- locations[
  locations$location == "Westwood Hills",
]

stopifnot(nrow(selected) == 1)

point <- vect(selected)

stopifnot(same.crs(exposure, point))

# Reuse the baseline geometry and thresholds from E01–E07.

directions <- fire_exp_dir(
  exposure = exposure,
  value = point,
  t_lengths = c(2000, 2000, 2000),
  interval = 10,
  thresh_exp = 0.60,
  thresh_viable = 0.80
)

results <- as.data.frame(directions, geom = NULL)

cat("\nReturned columns:\n")
print(names(results))

cat("\nDirectional features:", nrow(results), "\n")

stopifnot(
  nrow(results) == 108,
  all(c("deg", "seg", "viable") %in% names(results)),
  length(unique(results$deg)) == 36,
  all(sort(unique(results$deg)) == seq(10, 360, 10)),
  all(sort(unique(as.character(results$seg))) ==
      c("seg1", "seg2", "seg3"))
)

stopifnot(
  !anyNA(results[, c("deg", "seg", "viable")]),
  all(results$viable %in% c(0, 1))
)

# Verify each bearing has exactly three segments.

counts <- table(results$deg)

stopifnot(all(counts == 3))

results <- results[
  order(
    results$deg,
    match(
      as.character(results$seg),
      c("seg1", "seg2", "seg3")
    )
  ),
]

# Preserve the original returned attributes.

dir.create(
  dirname(output_path),
  recursive = TRUE,
  showWarnings = FALSE
)

write.csv(
  results,
  output_path,
  row.names = FALSE
)

cat("\n=== VIABILITY BY SEGMENT ===\n")

print(
  aggregate(
    viable ~ seg,
    data = results,
    FUN = function(x) c(
      viable = sum(x == 1),
      nonviable = sum(x == 0)
    )
  )
)

cat("\n=== OVERALL CLASSIFICATION ===\n")

print(table(results$viable))

cat("\n=== SELECTED BEARINGS ===\n")

print(
  results[
    results$deg %in% c(0, 90, 180, 270),
    c("deg", "seg", "viable")
  ],
  row.names = FALSE
)

cat("\nOutput:", output_path, "\n")
cat("D10.6 baseline assessment: PASSED\n")
