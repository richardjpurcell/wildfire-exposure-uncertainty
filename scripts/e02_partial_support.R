# E02: Partial directional exposure support
# Synthetic experiment; no wildfire observations.

library(terra)
library(fireexposuR)

source("R/directional_support.R")

# Synthetic landscape.
exposure <- rast(
  nrows = 200,
  ncols = 200,
  xmin = 0,
  xmax = 20000,
  ymin = 0,
  ymax = 20000,
  crs = "EPSG:3978"
)

# Reference point at raster centre.
point <- vect(
  "POINT (10000 10000)",
  crs = crs(exposure)
)

# Radial distance from the reference point.
x <- init(exposure, "x")
y <- init(exposure, "y")

distance <- sqrt(
  (x - 10000)^2 +
  (y - 10000)^2
)

# High-exposure circle with 3500 m radius.
exposure <- ifel(distance <= 3500, 0.75, 0.40)
names(exposure) <- "exposure"

# Original directional classification.
directions <- fire_exp_dir(
  exposure = exposure,
  value = point,
  t_lengths = c(2000, 2000, 2000),
  interval = 10,
  thresh_exp = 0.60,
  thresh_viable = 0.80
)

# Continuous support reconstruction.
support <- directional_support(
  exposure = exposure,
  transects = directions,
  thresh_exp = 0.60,
  thresh_viable = 0.80
)

original <- as.data.frame(directions)

comparison <- merge(
  original[, c("deg", "seg", "viable")],
  support,
  by = c("deg", "seg")
)

comparison$agreement <-
  comparison$viable == comparison$reconstructed_viable

cat("E02: Circular high-exposure region\n")
cat("Radius: 3500 m\n")
cat("Segments:", nrow(comparison), "\n")

cat("\nClassification by segment:\n")
print(table(comparison$seg, comparison$viable))

cat("\nContinuous support by segment:\n")
print(
  aggregate(
    high_fraction ~ seg,
    data = comparison,
    FUN = function(x) {
      c(min = min(x), mean = mean(x), max = max(x))
    }
  )
)

cat("\nSelected bearings:\n")
print(
  comparison[
    comparison$deg %in% c(90, 180, 270, 360),
    c("deg", "seg", "high_fraction",
      "decision_margin", "viable")
  ],
  row.names = FALSE,
  digits = 5
)

cat(
  "\nMatching classifications:",
  sum(comparison$agreement),
  "of",
  nrow(comparison),
  "\n"
)

stopifnot(
  nrow(comparison) == 108,
  !anyNA(comparison$high_fraction),
  all(comparison$high_fraction >= 0),
  all(comparison$high_fraction <= 1.000001),
  all(comparison$agreement),
  any(comparison$high_fraction > 0 &
      comparison$high_fraction < 1)
)

cat("\nE02 baseline test: PASSED\n")

# E02 second representation: 3550 m radius

exposure_b <- ifel(distance <= 3550, 0.75, 0.40)
names(exposure_b) <- "exposure"

directions_b <- fire_exp_dir(
  exposure = exposure_b,
  value = point,
  t_lengths = c(2000, 2000, 2000),
  interval = 10,
  thresh_exp = 0.60,
  thresh_viable = 0.80
)

support_b <- directional_support(
  exposure = exposure_b,
  transects = directions_b,
  thresh_exp = 0.60,
  thresh_viable = 0.80
)

original_b <- as.data.frame(directions_b)

comparison_b <- merge(
  original_b[, c("deg", "seg", "viable")],
  support_b,
  by = c("deg", "seg")
)

stopifnot(
  nrow(comparison_b) == 108,
  all(comparison_b$viable ==
      comparison_b$reconstructed_viable)
)

# Compare scenarios using bearing and segment identity.
paired <- merge(
  comparison[, c(
    "deg", "seg", "high_fraction",
    "decision_margin", "viable"
  )],
  comparison_b[, c(
    "deg", "seg", "high_fraction",
    "decision_margin", "viable"
  )],
  by = c("deg", "seg"),
  suffixes = c("_a", "_b")
)

paired$delta_support <-
  paired$high_fraction_b - paired$high_fraction_a

paired$classification_changed <-
  paired$viable_a != paired$viable_b

cat("\nE02 scenario comparison: 3500 m vs 3550 m\n")

cat("\nSupport change by segment:\n")
print(
  aggregate(
    delta_support ~ seg,
    data = paired,
    FUN = function(x) {
      c(min = min(x), mean = mean(x), max = max(x))
    }
  )
)

cat("\nClassification changes:",
    sum(paired$classification_changed),
    "of", nrow(paired), "\n")

cat("\nMiddle segment comparison:\n")
print(
  paired[
    paired$seg == "seg2",
    c(
      "deg",
      "high_fraction_a",
      "high_fraction_b",
      "delta_support",
      "viable_a",
      "viable_b"
    )
  ],
  row.names = FALSE,
  digits = 5
)

stopifnot(
  nrow(paired) == 108,
  !anyNA(paired$delta_support),
  all(paired$delta_support >= -1e-8),
  any(paired$delta_support > 0.01),
  sum(paired$classification_changed) == 0
)

cat("\nE02 scenario comparison: PASSED\n")
