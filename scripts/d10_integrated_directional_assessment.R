# D10.7b — Integrated Westwood Hills directional assessment
#
# Uses verified D09 reference exposure and established
# E01-E07 support/coverage methods.
#
# Experimental thresholds, not operational safety limits.

library(terra)
library(sf)
library(fireexposuR)

source("R/directional_support.R")
source("R/directional_coverage.R")
source("R/directional_assessment.R")

cat("\n=== D10.7b: INTEGRATED DIRECTIONAL ASSESSMENT ===\n")

exposure_path <- paste0(
  "data/processed/visualization/",
  "d09_reference_exposure_2026_500m.tif"
)

points_path <- paste0(
  "data/processed/study-window/",
  "reference_points.gpkg"
)

baseline_path <- paste0(
  "outputs/tables/",
  "d10_baseline_directional_assessment.csv"
)

output_path <- paste0(
  "outputs/tables/",
  "d10_integrated_directional_assessment.csv"
)

stopifnot(
  file.exists(exposure_path),
  file.exists(points_path),
  file.exists(baseline_path)
)

exposure <- rast(exposure_path)

locations <- st_read(points_path, quiet = TRUE)

selected <- locations[
  locations$location == "Westwood Hills",
]

stopifnot(nrow(selected) == 1)

point <- vect(selected)

stopifnot(same.crs(exposure, point))

# Reconstruct the same 108 directional segments.

transects <- fire_exp_dir(
  exposure = exposure,
  value = point,
  t_lengths = c(2000, 2000, 2000),
  interval = 10,
  thresh_exp = 0.60,
  thresh_viable = 0.80
)

integrated <- directional_assessment(
  exposure = exposure,
  transects = transects,
  thresh_exp = 0.60,
  thresh_viable = 0.80
)

baseline <- read.csv(
  baseline_path,
  stringsAsFactors = FALSE
)

cat("\n=== RETURNED MEASUREMENTS ===\n")
print(names(integrated))

stopifnot(
  nrow(integrated) == 108,
  nrow(baseline) == 108,
  !anyDuplicated(integrated[, c("deg", "seg")]),
  !anyDuplicated(baseline[, c("deg", "seg")]),
  all(c(
    "deg",
    "seg",
    "coverage_fraction",
    "observed_length_m",
    "observed_support",
    "evidence_status"
  ) %in% names(integrated))
)

# Match to the verified baseline by segment identity.

result <- merge(
  baseline[, c("deg", "seg", "viable")],
  integrated,
  by = c("deg", "seg"),
  all = TRUE,
  sort = TRUE
)

stopifnot(
  nrow(result) == 108,
  !anyNA(result[, c("deg", "seg", "viable")])
)

# Compare the integrated binary classification against
# the original fire_exp_dir classification.

if ("reconstructed_viable" %in% names(result)) {
  mismatches <- sum(
    result$viable != result$reconstructed_viable
  )

  cat("\nReconstructed classification mismatches:",
      mismatches, "\n")

  stopifnot(mismatches == 0)
}

# Coverage must remain between zero and one.

tol <- 1e-8

stopifnot(
  all(is.finite(result$coverage_fraction)),
  all(result$coverage_fraction >= -tol),
  all(result$coverage_fraction <= 1 + tol),
  all(result$evidence_status %in%
      c("complete", "partial", "missing"))
)

# Preserve the original integrated measurements.
dir.create(
  dirname(output_path),
  recursive = TRUE,
  showWarnings = FALSE
)

write.csv(
  result,
  output_path,
  row.names = FALSE
)

cat("\n=== EVIDENCE STATUS ===\n")
print(table(result$evidence_status))

cat("\n=== COVERAGE DISTRIBUTION ===\n")
print(summary(result$coverage_fraction))

cat("\n=== OBSERVED SUPPORT DISTRIBUTION ===\n")
print(summary(result$observed_support))

cat("\n=== VIABILITY BY SEGMENT ===\n")
print(
  with(
    result,
    table(seg, viable)
  )
)

cat("\n=== SELECTED DIRECTIONS ===\n")
print(
  result[
    result$deg %in% c(90, 180, 270, 360),
    intersect(
      c(
        "deg",
        "seg",
        "viable",
        "support_fraction",
        "observed_support",
        "coverage_fraction",
        "evidence_status"
      ),
      names(result)
    )
  ],
  row.names = FALSE
)

cat("\nOutput:", output_path, "\n")
cat("D10.7b integrated assessment: PASSED\n")
