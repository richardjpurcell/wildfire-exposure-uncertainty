# Synthetic directional exposure test
# fireexposuR 1.2.0
# No external datasets required.

library(terra)
library(fireexposuR)

# Create a 20 x 20 km uniform exposure raster.
exposure <- rast(
  nrows = 200,
  ncols = 200,
  xmin = 0,
  xmax = 20000,
  ymin = 0,
  ymax = 20000,
  crs = "EPSG:3978"
)

values(exposure) <- 0.75

# Reference point at the centre of the raster.
point <- vect(
  "POINT (10000 10000)",
  crs = crs(exposure)
)

# Run directional assessment.
directions <- fire_exp_dir(
  exposure = exposure,
  value = point,
  t_lengths = c(2000, 2000, 2000),
  interval = 10,
  thresh_exp = 0.60,
  thresh_viable = 0.80
)

# Inspect results.
cat("Directional features:", nrow(directions), "\n")
cat("Attribute names:", names(directions), "\n")

results <- as.data.frame(directions)

cat("\nViability classifications:\n")
print(table(results$viable, useNA = "ifany"))

cat("\nSegment counts:\n")
print(table(results$seg, useNA = "ifany"))

# Basic structural checks.
stopifnot(
  inherits(directions, "SpatVector"),
  nrow(directions) == 108,
  all(c("deg", "seg", "viable") %in% names(directions)),
  !anyNA(results$viable),
  all(results$viable == 1),
  all(table(results$seg) == 36),
  length(unique(results$deg)) == 36
)

# Contrasting case: uniform exposure below threshold.
exposure_low <- exposure
values(exposure_low) <- 0.40

directions_low <- fire_exp_dir(
  exposure = exposure_low,
  value = point,
  t_lengths = c(2000, 2000, 2000),
  interval = 10,
  thresh_exp = 0.60,
  thresh_viable = 0.80
)

results_low <- as.data.frame(directions_low)

cat("\nLow-exposure viability classifications:\n")
print(table(results_low$viable, useNA = "ifany"))

stopifnot(
  nrow(directions_low) == 108,
  !anyNA(results_low$viable),
  all(results_low$viable == 0)
)

cat("\nSynthetic directional test: PASSED\n")
