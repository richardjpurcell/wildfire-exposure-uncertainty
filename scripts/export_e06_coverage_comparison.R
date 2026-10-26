# E06: Export paired evidence-coverage comparison
# Synthetic landscapes; no real wildfire observations.

library(terra)
library(fireexposuR)

source("R/directional_support.R")
source("R/directional_coverage.R")
source("R/directional_assessment.R")

template <- rast(
  nrows = 200,
  ncols = 200,
  xmin = 0,
  xmax = 20000,
  ymin = 0,
  ymax = 20000,
  crs = "EPSG:3978"
)

x <- init(template, "x")

point <- vect(
  "POINT (10000 10000)",
  crs = crs(template)
)

measured <- ifel(x < 10000, 0.40, 0.75)
missing <- ifel(x < 10000, NA_real_, 0.75)

names(measured) <- "exposure"
names(missing) <- "exposure"

# Generate identical directional geometries for comparison.
directions <- fire_exp_dir(
  exposure = measured,
  value = point,
  t_lengths = c(2000, 2000, 2000),
  interval = 10,
  thresh_exp = 0.60,
  thresh_viable = 0.80
)

measured_result <- directional_assessment(
  exposure = measured,
  transects = directions
)

missing_result <- directional_assessment(
  exposure = missing,
  transects = directions
)

measured_result$scenario <- "Measured"
missing_result$scenario <- "Missing"

combined <- rbind(measured_result, missing_result)

# Verify that classifications are identical for paired segments.
paired <- merge(
  measured_result[, c("deg", "seg", "reconstructed_viable")],
  missing_result[, c("deg", "seg", "reconstructed_viable")],
  by = c("deg", "seg"),
  suffixes = c("_measured", "_missing")
)

stopifnot(
  nrow(measured_result) == 108,
  nrow(missing_result) == 108,
  nrow(combined) == 216,
  all(
    paired$reconstructed_viable_measured ==
    paired$reconstructed_viable_missing
  )
)

dir.create("outputs", showWarnings = FALSE)

output_path <- "outputs/e06_coverage_comparison.csv"

write.csv(
  combined,
  output_path,
  row.names = FALSE
)

cat("E06 evidence-coverage comparison exported:\n")
cat(output_path, "\n")
cat("Rows:", nrow(combined), "\n")

cat("\nMean evidence coverage by scenario:\n")
print(
  aggregate(
    coverage_fraction ~ scenario,
    data = combined,
    FUN = mean
  ),
  row.names = FALSE
)

cat("\nClassification agreement:",
    sum(
      paired$reconstructed_viable_measured ==
      paired$reconstructed_viable_missing
    ),
    "of", nrow(paired), "\n")

cat("\nE06 comparison export: PASSED\n")
