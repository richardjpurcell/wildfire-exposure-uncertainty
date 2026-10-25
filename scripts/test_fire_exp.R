# Synthetic functional test for fireexposuR 1.2.0
# No external datasets required.

library(terra)
library(fireexposuR)

# Create a 51 x 51 raster at 100 m resolution.
hazard <- rast(
  nrows = 51,
  ncols = 51,
  xmin = 0,
  xmax = 5100,
  ymin = 0,
  ymax = 5100,
  crs = "EPSG:3978"
)

values(hazard) <- 0

# Central 5 x 5 cells represent hazardous fuel.
m <- matrix(0, nrow = 51, ncol = 51)
m[24:28, 24:28] <- 1
values(hazard) <- as.vector(t(m))

# Calculate exposure.
exposure <- fire_exp(hazard, t_dist = 500)

# Inspect results.
cat("Hazard dimensions:",
    nrow(hazard), "x", ncol(hazard), "\n")

cat("Hazardous cells:",
    global(hazard, "sum", na.rm = TRUE)[1, 1], "\n")

cat("Exposure dimensions:",
    nrow(exposure), "x", ncol(exposure), "\n")

cat("Exposure range:\n")
print(global(exposure, c("min", "max"), na.rm = TRUE))

cat("Exposure summary:\n")
print(global(exposure, "mean", na.rm = TRUE))

stopifnot(
  inherits(exposure, "SpatRaster"),
  nrow(exposure) == 51,
  ncol(exposure) == 51
)

# Additional numerical sanity checks.
exposure_values <- values(exposure, mat = FALSE)
valid_values <- exposure_values[!is.na(exposure_values)]

stopifnot(
  length(valid_values) > 0,
  all(is.finite(valid_values)),
  all(valid_values >= 0),
  all(valid_values <= 1),
  any(valid_values > 0)
)

cat("Valid exposure cells:", length(valid_values), "\n")
cat("Missing exposure cells:", sum(is.na(exposure_values)), "\n")

cat("Synthetic fire_exp test: PASSED\n")
