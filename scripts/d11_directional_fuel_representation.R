# D11.2A — Directional sensitivity to unresolved fuel classification
#
# Compare complete D09 2026 exposure surfaces:
#   Reference: unresolved FBP code 13 assigned 0
#   Upper:     unresolved FBP code 13 assigned 1
#
# Fixed:
#   Westwood Hills reference point
#   36 bearings, three nominal 2 km segments
#   500 m exposure neighbourhood (already calculated in D09)
#   Exposure threshold 0.60
#   Viability threshold 0.80
#
# Experimental sensitivity, not validated fire behaviour or safety.

suppressPackageStartupMessages({
  library(terra)
  library(sf)
  library(fireexposuR)
})

source("R/directional_support.R")

cat("\n=== D11.2A: DIRECTIONAL FUEL REPRESENTATION ===\n")

input_dir <- "data/processed/visualization"

reference <- rast(file.path(
  input_dir, "d09_reference_exposure_2026_500m.tif"
))

upper <- rast(file.path(
  input_dir, "d09_upper_exposure_2026_500m.tif"
))

status <- rast(file.path(
  input_dir, "d09_reference_input_status_2026.tif"
))

stopifnot(
  compareGeom(reference, upper, stopOnError = FALSE),
  compareGeom(reference, status, stopOnError = FALSE)
)

rv <- values(reference, mat = FALSE)
uv <- values(upper, mat = FALSE)
sv <- values(status, mat = FALSE)

valid <- is.finite(rv) & is.finite(uv)

stopifnot(
  sum(valid) == 36100,
  identical(is.finite(rv), is.finite(uv)),
  sum(sv == 2) == 1326,
  all(uv[valid] >= rv[valid] - 1e-6)
)

locations <- st_read(
  "data/processed/study-window/reference_points.gpkg",
  quiet = TRUE
)

selected <- locations[
  locations$location == "Westwood Hills",
]

stopifnot(nrow(selected) == 1)

point <- vect(selected)

stopifnot(same.crs(reference, point))

run_directions <- function(exposure) {
  fire_exp_dir(
    exposure = exposure,
    value = point,
    t_lengths = c(2000, 2000, 2000),
    interval = 10,
    thresh_exp = 0.60,
    thresh_viable = 0.80
  )
}

cat("\nCalculating directional geometries and classifications...\n")

ref_dir <- run_directions(reference)
upper_dir <- run_directions(upper)

ref_sf <- st_as_sf(ref_dir)
upper_sf <- st_as_sf(upper_dir)

key <- function(x) paste(x$deg, x$seg, sep = "_")

ref_sf <- ref_sf[order(key(ref_sf)), ]
upper_sf <- upper_sf[order(key(upper_sf)), ]

stopifnot(
  nrow(ref_sf) == 108,
  nrow(upper_sf) == 108,
  identical(key(ref_sf), key(upper_sf)),
  !anyDuplicated(key(ref_sf))
)

geometry_matches <- st_equals_exact(
  st_geometry(ref_sf),
  st_geometry(upper_sf),
  par = 1e-7,
  sparse = FALSE
)

stopifnot(all(diag(geometry_matches)))

cat("Matched geometries: 108/108\n")

ref_support <- directional_support(
  reference, ref_dir, 0.60, 0.80
)

upper_support <- directional_support(
  upper, ref_dir, 0.60, 0.80
)

baseline <- read.csv(
  "outputs/tables/d10_baseline_directional_assessment.csv",
  stringsAsFactors = FALSE
)

ref_package <- as.data.frame(ref_dir, geom = NULL)
upper_package <- as.data.frame(upper_dir, geom = NULL)

result <- merge(
  ref_support,
  upper_support,
  by = c("deg", "seg"),
  suffixes = c("_reference", "_upper")
)

result <- merge(
  result,
  baseline[, c("deg", "seg", "viable")],
  by = c("deg", "seg")
)

result <- merge(
  result,
  ref_package[, c("deg", "seg", "viable")],
  by = c("deg", "seg"),
  suffixes = c("_baseline", "_package_reference")
)

result <- merge(
  result,
  upper_package[, c("deg", "seg", "viable")],
  by = c("deg", "seg")
)

names(result)[names(result) == "viable"] <- "viable_package_upper"

stopifnot(
  nrow(result) == 108,
  !anyDuplicated(result[, c("deg", "seg")]),
  !anyNA(result),
  all(result$viable_baseline == result$viable_package_reference),
  all(result$viable_baseline ==
      result$reconstructed_viable_reference),
  all(result$viable_package_upper ==
      result$reconstructed_viable_upper)
)

result$delta_support <-
  result$high_fraction_upper -
  result$high_fraction_reference

result$transition <- with(
  result,
  ifelse(
    viable_baseline == 0 & viable_package_upper == 0,
    "stable_nonviable",
    ifelse(
      viable_baseline == 1 & viable_package_upper == 1,
      "stable_viable",
      ifelse(
        viable_baseline == 0 & viable_package_upper == 1,
        "newly_viable",
        "no_longer_viable"
      )
    )
  )
)

result <- result[
  order(
    result$deg,
    match(result$seg, c("seg1", "seg2", "seg3"))
  ),
]

rownames(result) <- NULL

stopifnot(
  sum(result$viable_baseline == 1) == 42,
  sum(result$viable_package_upper == 1) == 58,
  sum(result$transition == "newly_viable") == 16,
  sum(result$transition == "no_longer_viable") == 0,
  all(result$delta_support >= -1e-6)
)

output <- result[, c(
  "deg",
  "seg",
  "length_m_reference",
  "high_fraction_reference",
  "high_fraction_upper",
  "delta_support",
  "decision_margin_reference",
  "decision_margin_upper",
  "viable_baseline",
  "viable_package_upper",
  "transition"
)]

cat("\n=== CLASSIFICATION TRANSITIONS ===\n")
print(table(output$transition))

cat("\n=== SUPPORT CHANGE ===\n")
print(summary(output$delta_support))

cat("\n=== TRANSITIONS BY SEGMENT ===\n")
print(table(output$seg, output$transition))

cat("\n=== CHANGED SEGMENTS ===\n")
print(
  output[output$transition == "newly_viable", ],
  row.names = FALSE
)

# Write only after all analytical assertions pass.

output_path <- paste0(
  "outputs/tables/",
  "d11_directional_fuel_representation.csv"
)

stopifnot(!file.exists(output_path))

write.csv(output, output_path, row.names = FALSE)

cat("\n=== VERIFICATION ===\n")
cat("Reference baseline: 42 viable\n")
cat("Upper scenario: 58 viable\n")
cat("Newly viable: 16\n")
cat("Package/reconstruction agreement: 108/108\n")
cat("Matched geometries: 108/108\n")
cat("Output:", output_path, "\n")
cat("\nD11.2A reproducibility: PASSED\n")
