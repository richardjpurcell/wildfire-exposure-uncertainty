# E07: Integrated synthetic exposure and evidence landscape
# Initial step: construct and verify the landscape.

library(terra)

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
y <- init(template, "y")

distance <- sqrt(
  (x - 10000)^2 +
  (y - 10000)^2
)

# E05 baseline radial gradient.
baseline <- clamp(
  0.90 - 0.0001 * distance,
  lower = 0.20,
  upper = 0.90,
  values = TRUE
)

# Controlled eastern exposure increment.
exposure <- ifel(
  x >= 10000,
  baseline + 0.10,
  baseline
)

exposure <- clamp(
  exposure,
  lower = 0.20,
  upper = 0.90,
  values = TRUE
)

# Introduce missing evidence southwest of centre.
missing_region <- (
  x >= 6000 & x < 10000 &
  y >= 6000 & y < 10000
)

exposure <- ifel(
  missing_region,
  NA_real_,
  exposure
)

names(exposure) <- "exposure"

available <- !is.na(exposure)

cat("E07: Integrated synthetic landscape\n")

cat("\nRaster dimensions:\n")
print(dim(exposure))

cat("\nEvidence availability:\n")
available_cells <- global(available, "sum", na.rm = TRUE)[1, 1]

cat("Available cells:", available_cells, "\n")
cat("Missing cells:", ncell(exposure) - available_cells, "\n")
cat("Coverage fraction:", available_cells / ncell(exposure), "\n")

cat("\nAvailable exposure summary:\n")
print(global(exposure, c("min", "mean", "max"), na.rm = TRUE))

stopifnot(
  ncell(exposure) == 40000,
  available_cells == 38400,
  anyNA(values(exposure)),
  global(exposure, "max", na.rm = TRUE)[1, 1] <= 0.90
)

cat("\nE07 landscape construction: PASSED\n")

# E07 baseline directional assessment

library(fireexposuR)

source("R/directional_support.R")
source("R/directional_coverage.R")
source("R/directional_assessment.R")

point <- vect(
  "POINT (10000 10000)",
  crs = crs(exposure)
)

directions <- fire_exp_dir(
  exposure = exposure,
  value = point,
  t_lengths = c(2000, 2000, 2000),
  interval = 10,
  thresh_exp = 0.60,
  thresh_viable = 0.80
)

assessment <- directional_assessment(
  exposure = exposure,
  transects = directions,
  thresh_exp = 0.60,
  thresh_viable = 0.80
)

original <- as.data.frame(directions)

comparison <- merge(
  original[, c("deg", "seg", "viable")],
  assessment,
  by = c("deg", "seg")
)

stopifnot(
  nrow(comparison) == 108,
  all(comparison$viable ==
      comparison$reconstructed_viable)
)

cat("\nE07 baseline directional assessment:\n")

cat("\nClassification counts:\n")
print(table(comparison$seg, comparison$viable))

cat("\nEvidence coverage summary:\n")
print(summary(comparison$coverage_fraction))

cat("\nEvidence status counts:\n")
print(table(comparison$evidence_status))

cat("\nSelected directional measurements:\n")

selected <- comparison[
  comparison$deg %in% c(45, 90, 180, 225, 270),
  c(
    "deg",
    "seg",
    "high_fraction",
    "coverage_fraction",
    "observed_support",
    "reconstructed_viable",
    "evidence_status"
  )
]

print(
  selected[order(selected$deg, selected$seg), ],
  row.names = FALSE,
  digits = 5
)

cat("\nE07 baseline assessment: PASSED\n")

# E07 diagnostic: near-zero evidence coverage

near_zero <- assessment[
  assessment$coverage_fraction > 0 &
    assessment$coverage_fraction < 0.001,
  c(
    "deg",
    "seg",
    "length_m",
    "high_length_m",
    "observed_length_m",
    "coverage_fraction",
    "observed_support",
    "evidence_status"
  )
]

cat("\nE07 near-zero coverage diagnostic:\n")
cat("Segments:", nrow(near_zero), "\n")

print(
  near_zero[
    order(near_zero$deg, near_zero$seg),
  ],
  row.names = FALSE,
  digits = 10
)

cat("\nE07 near-zero coverage diagnostic: COMPLETE\n")

# E07: Verify negligible coverage is not treated as observed support.

negligible <- assessment[
  assessment$coverage_fraction > 0 &
    assessment$coverage_fraction <= 1e-8,
]

cat("\nE07 negligible-coverage verification:\n")
cat("Affected segments:", nrow(negligible), "\n")

cat(
  "Undefined observed-only support:",
  sum(is.na(negligible$observed_support)),
  "of",
  nrow(negligible),
  "\n"
)

stopifnot(
  nrow(negligible) == 9,
  all(is.na(negligible$observed_support)),
  all(negligible$evidence_status == "missing"),
  all(negligible$reconstructed_viable == 0)
)

cat("\nE07 negligible-coverage correction: PASSED\n")
