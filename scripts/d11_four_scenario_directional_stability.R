# D11.4 — Directional stability across 2024 and 2026 FBP editions
#
# Uses the same geometry and thresholds as D10 and D11.2A.
# Exposure surfaces are normalized to IEEE 754 float32 precision
# before directional assessment, reproducing the saved D09 rasters.
#
# Outputs:
# outputs/tables/d11_four_scenario_directional_stability.csv

suppressPackageStartupMessages({
  library(terra)
  library(sf)
  library(fireexposuR)
})

source("R/directional_support.R")

cat("\n=== D11.4: MAINTAINED FOUR-SCENARIO ANALYSIS ===\n")

output <- "outputs/tables/d11_four_scenario_directional_stability.csv"

# Do not silently overwrite a previously reviewed artifact.
stopifnot(!file.exists(output))

r24 <- rast(
  "data/processed/study-window/fbp_2024_aligned_100m.tif"
)
r26 <- rast(
  "data/processed/study-window/fbp_2026_candidate_100m.tif"
)

stopifnot(
  compareGeom(r24, r26, stopOnError = FALSE)
)

fuel24 <- c(2, 3, 4, 11, 13, 31, 415, 625, 650, 675)
fuel26 <- c(1, 2, 3, 4, 11, 31, 625, 650, 675)
nonfuel <- c(101, 102)

float32 <- function(x) {
  raw <- writeBin(
    as.numeric(x),
    raw(),
    size = 4,
    endian = .Platform$endian
  )

  readBin(
    raw,
    what = "numeric",
    n = length(x),
    size = 4,
    endian = .Platform$endian
  )
}

make_surface <- function(r, fuel, unresolved, fill) {
  codes <- values(r, mat = FALSE)

  stopifnot(
    !anyNA(codes),
    all(codes %in% c(fuel, nonfuel, unresolved))
  )

  hazard <- r

  x <- rep(NA_real_, length(codes))
  x[codes %in% fuel] <- 1
  x[codes %in% nonfuel] <- 0
  x[codes == unresolved] <- fill

  values(hazard) <- x

  exposure <- fire_exp(hazard, t_dist = 500)

  v <- values(exposure, mat = FALSE)
  finite <- is.finite(v)

  v[finite] <- float32(v[finite])
  values(exposure) <- v

  exposure
}

cat("\n=== RECONSTRUCTING FOUR EXPOSURE SURFACES ===\n")

surfaces <- list(
  y24L = make_surface(r24, fuel24, 105, 0),
  y24U = make_surface(r24, fuel24, 105, 1),
  y26L = make_surface(r26, fuel26, 13, 0),
  y26U = make_surface(r26, fuel26, 13, 1)
)

d08 <- read.csv(
  "outputs/tables/d08_bounded_exposure_global.csv"
)

metric_names <- c(
  y24L = "mean_2024_lower",
  y24U = "mean_2024_upper",
  y26L = "mean_2026_lower",
  y26U = "mean_2026_upper"
)

cat("\n=== D08 GLOBAL VERIFICATION ===\n")

for (name in names(surfaces)) {
  v <- values(surfaces[[name]], mat = FALSE)

  target <- as.numeric(
    d08$value[d08$metric == metric_names[[name]]]
  )

  stopifnot(
    length(target) == 1,
    sum(is.finite(v)) == 36100,
    abs(mean(v, na.rm = TRUE) - target) < 1e-7
  )

  cat(name, ": PASSED\n")
}

cat("\n=== SAVED D09 EXACT NUMERICAL AGREEMENT ===\n")

saved_paths <- c(
  y26L = "data/processed/visualization/d09_reference_exposure_2026_500m.tif",
  y26U = "data/processed/visualization/d09_upper_exposure_2026_500m.tif"
)

for (name in names(saved_paths)) {
  a <- as.vector(values(surfaces[[name]], mat = FALSE))
  saved <- rast(saved_paths[[name]])
  b <- as.vector(values(saved, mat = FALSE))

  good_a <- is.finite(a)
  good_b <- is.finite(b)

  stopifnot(
    compareGeom(
      surfaces[[name]], saved,
      stopOnError = FALSE
    ),
    identical(good_a, good_b),
    sum(good_a) == 36100,
    all(a[good_a] == b[good_b])
  )

  cat(name, ": 36,100 finite values agree exactly\n")
}

cat("\n=== REFERENCE POINT AND GEOMETRY ===\n")

locations <- st_read(
  "data/processed/study-window/reference_points.gpkg",
  quiet = TRUE
)

selected <- locations[
  locations$location == "Westwood Hills",
]

stopifnot(nrow(selected) == 1)

point <- vect(selected)

assess <- function(exposure) {
  fire_exp_dir(
    exposure = exposure,
    value = point,
    t_lengths = c(2000, 2000, 2000),
    interval = 10,
    thresh_exp = 0.60,
    thresh_viable = 0.80
  )
}

key <- function(x) {
  paste(x$deg, x$seg, sep = "_")
}

reference <- st_as_sf(assess(surfaces$y26L))

stopifnot(
  nrow(reference) == 108,
  !anyDuplicated(key(reference))
)

comparison <- st_drop_geometry(
  reference[, c("deg", "seg")]
)

cat("\n=== FOUR DIRECTIONAL ASSESSMENTS ===\n")

for (name in names(surfaces)) {
  package_result <- st_as_sf(
    assess(surfaces[[name]])
  )

  a <- reference[order(key(reference)), ]
  b <- package_result[order(key(package_result)), ]

  stopifnot(
    nrow(b) == 108,
    identical(key(a), key(b))
  )

  same_geometry <- st_equals_exact(
    st_geometry(a),
    st_geometry(b),
    par = 1e-7,
    sparse = FALSE
  )

  stopifnot(all(diag(same_geometry)))

  reconstructed <- directional_support(
    exposure = surfaces[[name]],
    transects = vect(reference),
    thresh_exp = 0.60,
    thresh_viable = 0.80
  )

  verified <- merge(
    reconstructed,
    st_drop_geometry(package_result)[
      , c("deg", "seg", "viable")
    ],
    by = c("deg", "seg")
  )

  stopifnot(
    nrow(verified) == 108,
    !anyNA(verified),
    all(
      verified$reconstructed_viable ==
      verified$viable
    )
  )

  part <- verified[
    , c("deg", "seg", "viable", "high_fraction")
  ]

  names(part)[3:4] <- c(
    name,
    paste0(name, "_support")
  )

  comparison <- merge(
    comparison,
    part,
    by = c("deg", "seg")
  )

  cat(
    name,
    "| viable:", sum(part[[name]]),
    "| package agreement: 108/108",
    "| geometry agreement: 108/108\n"
  )
}

stopifnot(
  nrow(comparison) == 108,
  !anyNA(comparison),
  !anyDuplicated(key(comparison))
)

cat("\n=== HISTORICAL BASELINES ===\n")

baseline <- read.csv(
  "outputs/tables/d10_baseline_directional_assessment.csv"
)

earlier <- read.csv(
  "outputs/tables/d11_directional_fuel_representation.csv"
)

b <- merge(
  comparison,
  baseline[, c("deg", "seg", "viable")],
  by = c("deg", "seg")
)

u <- merge(
  comparison,
  earlier[, c("deg", "seg", "viable_package_upper")],
  by = c("deg", "seg")
)

stopifnot(
  nrow(b) == 108,
  nrow(u) == 108,
  all(b$y26L == b$viable),
  all(u$y26U == u$viable_package_upper),
  sum(comparison$y26L) == 42,
  sum(comparison$y26U) == 58
)

cat("D10 baseline: 108/108, 42 viable\n")
cat("D11.2A upper: 108/108, 58 viable\n")

cat("\n=== WITHIN-EDITION MONOTONICITY ===\n")

stopifnot(
  all(comparison$y24L <= comparison$y24U),
  all(comparison$y26L <= comparison$y26U),
  all(
    comparison$y24L_support <=
    comparison$y24U_support + 1e-6
  ),
  all(
    comparison$y26L_support <=
    comparison$y26U_support + 1e-6
  )
)

cat("2024 and 2026 ordering: PASSED\n")

cat("\n=== STABILITY CLASSIFICATION ===\n")

scenarios <- c("y24L", "y24U", "y26L", "y26U")

number_viable <- rowSums(
  as.matrix(comparison[, scenarios])
)

comparison$stability <- ifelse(
  number_viable == 4,
  "always_viable",
  ifelse(
    number_viable == 0,
    "always_nonviable",
    "variable"
  )
)

comparison$edition_difference <- ifelse(
  comparison$y24L == 1 & comparison$y26U == 0,
  "2024_viable_2026_nonviable",
  ifelse(
    comparison$y24U == 0 & comparison$y26L == 1,
    "2024_nonviable_2026_viable",
    "not_robustly_separated"
  )
)

stability_counts <- table(comparison$stability)
edition_counts <- table(comparison$edition_difference)

print(stability_counts)
print(edition_counts)

stopifnot(
  unname(stability_counts["always_viable"]) == 38,
  unname(stability_counts["always_nonviable"]) == 22,
  unname(stability_counts["variable"]) == 48,
  unname(
    edition_counts["2024_viable_2026_nonviable"]
  ) == 9,
  unname(
    edition_counts["2024_nonviable_2026_viable"]
  ) == 2,
  unname(
    edition_counts["not_robustly_separated"]
  ) == 97,
  sum(comparison$y24L) == 53,
  sum(comparison$y24U) == 82
)

cat("\n=== STABILITY BY SEGMENT ===\n")

print(table(
  comparison$seg,
  comparison$stability
))

cat("\n=== WRITING VERIFIED RESULTS ===\n")

comparison <- comparison[
  order(comparison$deg, comparison$seg),
]

columns <- c(
  "deg", "seg",
  "y24L", "y24U", "y26L", "y26U",
  "y24L_support", "y24U_support",
  "y26L_support", "y26U_support",
  "stability", "edition_difference"
)

comparison <- comparison[, columns]

stopifnot(
  nrow(comparison) == 108,
  ncol(comparison) == 12,
  !anyNA(comparison)
)

dir.create(
  dirname(output),
  recursive = TRUE,
  showWarnings = FALSE
)

write.csv(
  comparison,
  output,
  row.names = FALSE,
  na = ""
)

# Reopen independently of the in-memory result.
saved_table <- read.csv(
  output,
  stringsAsFactors = FALSE
)

stopifnot(
  nrow(saved_table) == 108,
  identical(names(saved_table), columns),
  !anyNA(saved_table),
  identical(
    as.character(saved_table$stability),
    as.character(comparison$stability)
  ),
  identical(
    as.character(saved_table$edition_difference),
    as.character(comparison$edition_difference)
  )
)

cat("CSV:", output, "\n")
cat("Rows:", nrow(saved_table), "\n")
cat("Columns:", ncol(saved_table), "\n")

cat("\n=== FINAL VERIFICATION ===\n")
cat("D08 exposure means: PASSED\n")
cat("D09 saved numerical values: PASSED\n")
cat("D10 and D11 baseline reproduction: PASSED\n")
cat("Four directional geometry checks: PASSED\n")
cat("Four independent classification checks: PASSED\n")
cat("Stability counts: 38 / 22 / 48\n")
cat("Robust edition differences: 9 / 2\n")
cat("CSV read-back: PASSED\n")

cat("\nD11.4 MAINTAINED ANALYSIS: PASSED\n")
