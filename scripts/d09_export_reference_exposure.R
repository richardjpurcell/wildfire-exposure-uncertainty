# D09 — Export reference exposure for paired visualization
#
# Reference:
# 2026 national FBP candidate
# 100 m grid; 500 m transmission distance
#
# Experimental binary vegetation representation:
#   1 = recognized vegetation
#   0 = explicit water/non-fuel
#   unresolved code 13 = assigned 0 for reference
#
# This is not a validated long-range fire-transmission
# hazard classification.
#
# Outputs are analytical rasters, not rendered maps.

library(terra)
library(fireexposuR)

cat("\n=== D09: Reference exposure export ===\n")

input <- paste0(
  "data/processed/study-window/",
  "fbp_2026_candidate_100m.tif"
)

output_dir <- "data/processed/visualization"
table_dir <- "outputs/tables"

dir.create(
  output_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

dir.create(
  table_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

fuel <- rast(input)
v <- values(fuel, mat = FALSE)

recognized <- c(
  1, 2, 3, 4,
  11, 31,
  625, 650, 675
)

explicit_nonfuel <- c(101, 102)
unresolved <- 13

stopifnot(
  nrow(fuel) == 200,
  ncol(fuel) == 200,
  all(res(fuel) == 100),
  !anyNA(v),
  all(v %in% c(
    recognized,
    explicit_nonfuel,
    unresolved
  ))
)

# ---------------------------------------
# Preserve original input interpretation
# ---------------------------------------

# 1 = recognized vegetation
# 0 = explicit non-fuel
# 2 = unresolved
#
# Status values are categorical, not continuous.

status <- fuel

s <- rep(2L, length(v))
s[v %in% recognized] <- 1L
s[v %in% explicit_nonfuel] <- 0L

values(status) <- s
names(status) <- "input_status"

stopifnot(
  sum(s == 1) == 28669,
  sum(s == 0) == 10005,
  sum(s == 2) == 1326
)

# ---------------------------------------
# Construct fixed-reference hazard raster
# ---------------------------------------

hazard <- fuel

h <- as.numeric(s == 1L)

values(hazard) <- h
names(hazard) <- "experimental_hazard"

# ---------------------------------------
# Calculate exposure
# ---------------------------------------

exposure <- fire_exp(
  hazard,
  t_dist = 500
)

names(exposure) <- "reference_exposure"

e <- values(exposure, mat = FALSE)
valid <- is.finite(e)

stopifnot(
  sum(valid) == 36100,
  all(e[valid] >= 0),
  all(e[valid] <= 1)
)

# ---------------------------------------
# Reconcile with D08
# ---------------------------------------

previous <- read.csv(
  "outputs/tables/d08_bounded_exposure_global.csv"
)

expected <- previous$value[
  previous$metric == "mean_2026_lower"
]

stopifnot(
  length(expected) == 1,
  abs(mean(e[valid]) - expected) < 1e-8
)

# ---------------------------------------
# Export only after validation
# ---------------------------------------

exposure_path <- file.path(
  output_dir,
  "d09_reference_exposure_2026_500m.tif"
)

status_path <- file.path(
  output_dir,
  "d09_reference_input_status_2026.tif"
)

metadata_path <- file.path(
  table_dir,
  "d09_reference_exposure_metadata.csv"
)

writeRaster(
  exposure,
  exposure_path,
  overwrite = TRUE,
  datatype = "FLT4S",
  NAflag = -9999
)

writeRaster(
  status,
  status_path,
  overwrite = TRUE,
  datatype = "INT1U"
)

metadata <- data.frame(
  property = c(
    "source",
    "classification_rule",
    "unresolved_treatment",
    "crs_epsg",
    "resolution_m",
    "transmission_distance_m",
    "valid_exposure_cells",
    "mean_exposure",
    "median_exposure",
    "minimum_exposure",
    "maximum_exposure",
    "recognized_vegetation_cells",
    "explicit_nonfuel_cells",
    "unresolved_input_cells"
  ),
  value = c(
    "2026 FBP candidate",
    "broad binary vegetation",
    "code 13 assigned zero for reference",
    "3978",
    "100",
    "500",
    as.character(sum(valid)),
    sprintf("%.8f", mean(e[valid])),
    sprintf("%.8f", median(e[valid])),
    sprintf("%.8f", min(e[valid])),
    sprintf("%.8f", max(e[valid])),
    as.character(sum(s == 1)),
    as.character(sum(s == 0)),
    as.character(sum(s == 2))
  )
)

write.csv(
  metadata,
  metadata_path,
  row.names = FALSE
)

cat("\n=== Outputs ===\n")
cat(exposure_path, "\n")
cat(status_path, "\n")
cat(metadata_path, "\n")

cat("\n=== Reference verification ===\n")
cat("Valid exposure cells:", sum(valid), "\n")
cat("Mean exposure:", mean(e[valid]), "\n")
cat("Unresolved input cells:", sum(s == 2), "\n")

cat("\nD09 reference export: PASSED\n")
cat("No maps rendered.\n")
