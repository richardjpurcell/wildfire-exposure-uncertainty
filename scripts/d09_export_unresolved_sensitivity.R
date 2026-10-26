# D09 — Unresolved classification sensitivity
#
# 2026 FBP candidate; 100 m grid; 500 m neighborhood.
#
# Lower: unresolved code 13 assigned 0.
# Upper: unresolved code 13 assigned 1.
#
# Other recognized vegetation receives 1.
# Explicit water/non-fuel receives 0.
#
# Difference = upper minus lower exposure.
# This is deterministic scenario sensitivity, not
# statistical uncertainty or validated physical hazard.

library(terra)
library(fireexposuR)

cat("\n=== D09: Unresolved sensitivity export ===\n")

input <- rast(
  "data/processed/study-window/fbp_2026_candidate_100m.tif"
)

lower <- rast(
  "data/processed/visualization/d09_reference_exposure_2026_500m.tif"
)

status <- rast(
  "data/processed/visualization/d09_reference_input_status_2026.tif"
)

stopifnot(
  compareGeom(input, lower, stopOnError = FALSE),
  compareGeom(input, status, stopOnError = FALSE)
)

v <- values(input, mat = FALSE)
s <- values(status, mat = FALSE)

recognized <- c(1, 2, 3, 4, 11, 31, 625, 650, 675)

stopifnot(
  length(v) == 40000,
  !anyNA(v),
  all(s[v %in% recognized] == 1),
  all(s[v %in% c(101, 102)] == 0),
  all(s[v == 13] == 2),
  sum(s == 2) == 1326
)

# Independently form upper-assignment hazard.
upper_hazard <- input
values(upper_hazard) <- as.numeric(
  v %in% c(recognized, 13)
)

upper <- fire_exp(upper_hazard, t_dist = 500)
names(upper) <- "upper_exposure"

sensitivity <- upper - lower
names(sensitivity) <- "unresolved_sensitivity"

lv <- values(lower, mat = FALSE)
uv <- values(upper, mat = FALSE)
dv <- values(sensitivity, mat = FALSE)

valid <- is.finite(lv) & is.finite(uv)

stopifnot(
  sum(valid) == 36100,
  identical(is.finite(lv), is.finite(uv)),
  all(dv[valid] >= -1e-7),
  all(dv[valid] <= 1 + 1e-7)
)

# Cross-check with maintained D08 table.
d08 <- read.csv(
  "outputs/tables/d08_bounded_exposure_global.csv"
)

lookup <- function(metric) {
  result <- d08$value[d08$metric == metric]
  stopifnot(length(result) == 1)
  as.numeric(result)
}

mean_lower <- mean(lv[valid])
mean_upper <- mean(uv[valid])
mean_width <- mean(dv[valid])

stopifnot(
  abs(mean_lower - lookup("mean_2026_lower")) < 1e-7,
  abs(mean_upper - lookup("mean_2026_upper")) < 1e-7,
  abs(mean_width - (mean_upper - mean_lower)) < 1e-7
)

# A second consistency check:
# Difference is the 500 m neighborhood fraction of
# unresolved cells, because that is the only variable
# changed between the two assignments.
unresolved_indicator <- input
values(unresolved_indicator) <- as.numeric(v == 13)

direct <- fire_exp(
  unresolved_indicator,
  t_dist = 500
)

direct_values <- values(direct, mat = FALSE)

stopifnot(
  identical(is.finite(dv), is.finite(direct_values)),
  max(abs(dv[valid] - direct_values[valid])) < 1e-6
)

output_dir <- "data/processed/visualization"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

upper_path <- file.path(
  output_dir,
  "d09_upper_exposure_2026_500m.tif"
)

width_path <- file.path(
  output_dir,
  "d09_unresolved_sensitivity_2026_500m.tif"
)

writeRaster(
  upper,
  upper_path,
  overwrite = TRUE,
  datatype = "FLT4S",
  NAflag = -9999
)

writeRaster(
  sensitivity,
  width_path,
  overwrite = TRUE,
  datatype = "FLT4S",
  NAflag = -9999
)

cat("\n=== Verified values ===\n")
cat("Valid cells:", sum(valid), "\n")
cat("Mean lower exposure:", mean_lower, "\n")
cat("Mean upper exposure:", mean_upper, "\n")
cat("Mean sensitivity:", mean_width, "\n")
cat("Maximum sensitivity:", max(dv[valid]), "\n")
cat("Nonzero sensitivity cells:", sum(dv[valid] > 1e-6), "\n")

cat("\n=== Generated rasters ===\n")
cat(upper_path, "\n")
cat(width_path, "\n")

cat("\nD09 unresolved sensitivity export: PASSED\n")
cat("No maps rendered.\n")
