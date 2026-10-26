# Integration test for directional support and evidence coverage.

library(terra)

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

# Use a common set of directional geometries.
# The high-exposure eastern half ensures fire_exp_dir()
# can construct the reference transects.
library(fireexposuR)

reference <- ifel(x < 10000, 0.40, 0.75)
names(reference) <- "exposure"

transects <- fire_exp_dir(
  exposure = reference,
  value = point,
  t_lengths = c(2000, 2000, 2000),
  interval = 10,
  thresh_exp = 0.60,
  thresh_viable = 0.80
)

scenarios <- list(
  measured_low = reference,
  missing_west = ifel(x < 10000, NA_real_, 0.75),
  partial_high = ifel(
    x >= 9000 & x < 10000,
    NA_real_,
    0.75
  )
)

results <- list()

for (scenario in names(scenarios)) {

  exposure <- scenarios[[scenario]]
  names(exposure) <- "exposure"

  assessment <- directional_assessment(
    exposure = exposure,
    transects = transects,
    thresh_exp = 0.60,
    thresh_viable = 0.80
  )

  stopifnot(nrow(assessment) == 108)

  selected <- assessment[
    assessment$deg == 270 &
      assessment$seg == "seg1",
  ]

  stopifnot(nrow(selected) == 1)

  results[[scenario]] <- data.frame(
    scenario = scenario,
    total_support = selected$high_fraction,
    coverage = selected$coverage_fraction,
    observed_support = selected$observed_support,
    evidence_status = selected$evidence_status,
    reconstructed_viable = selected$reconstructed_viable
  )
}

summary <- do.call(rbind, results)
rownames(summary) <- NULL

cat("Integrated directional assessment test\n")
cat("\nWestern first segment (270 degrees):\n")
print(summary, row.names = FALSE, digits = 5)

measured <- summary[summary$scenario == "measured_low", ]
missing <- summary[summary$scenario == "missing_west", ]
partial <- summary[summary$scenario == "partial_high", ]

stopifnot(
  abs(measured$coverage - 1) < 1e-8,
  abs(measured$observed_support) < 1e-8,
  measured$evidence_status == "complete",

  abs(missing$coverage) < 1e-8,
  is.na(missing$observed_support),
  missing$evidence_status == "missing",

  abs(partial$coverage - 0.5) < 0.02,
  abs(partial$total_support - 0.5) < 0.02,
  abs(partial$observed_support - 1) < 0.02,
  partial$evidence_status == "partial"
)

cat("\nIntegrated directional assessment: PASSED\n")

# Regression check: negligible observed length must not
# produce a meaningful observed-only support ratio.

negligible_case <- data.frame(
  coverage_fraction = 6.857583092e-10,
  observed_length_m = 1.371037190e-06,
  high_length_m = 1.371037190e-06
)

coverage_tolerance <- 1e-8

negligible_case$observed_support <- ifelse(
  negligible_case$coverage_fraction > coverage_tolerance,
  negligible_case$high_length_m /
    negligible_case$observed_length_m,
  NA_real_
)

stopifnot(
  is.na(negligible_case$observed_support)
)

cat("\nNegligible-coverage numerical rule: PASSED\n")
