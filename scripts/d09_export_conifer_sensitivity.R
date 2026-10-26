# D09.5 — Spatial C-2/C-4 assumption sensitivity
#
# Reproduces the corrected maintained D08 scenarios.
#
# A: C-2 included, C-4 excluded.
# B: C-2 excluded, C-4 included.
#
# Other recognized vegetation = 1.
# Explicit water/non-fuel = 0.
# Unresolved categories = 0 or 1.
#
# Delta = 2026 exposure - 2024 exposure.
#
# These hypothetical assignments are not validated
# wildfire transmission classifications.

library(terra)
library(fireexposuR)

cat("\n=== D09.5: Spatial conifer sensitivity ===\n")

r24 <- rast(
  "data/processed/study-window/fbp_2024_aligned_100m.tif"
)

r26 <- rast(
  "data/processed/study-window/fbp_2026_candidate_100m.tif"
)

stopifnot(
  compareGeom(r24, r26, stopOnError = FALSE),
  nrow(r24) == 200,
  ncol(r24) == 200,
  all(res(r24) == 100)
)

fuel24 <- c(2, 3, 4, 11, 13, 31, 415, 625, 650, 675)
fuel26 <- c(1, 2, 3, 4, 11, 31, 625, 650, 675)
nonfuel <- c(101, 102)

calculate <- function(r, fuel, unresolved, included, fill) {
  v <- values(r, mat = FALSE)

  stopifnot(
    !anyNA(v),
    all(v %in% c(fuel, nonfuel, unresolved)),
    included %in% c(2, 4),
    fill %in% c(0, 1)
  )

  excluded <- if (included == 2) 4 else 2

  x <- as.numeric(v %in% fuel)
  x[v == excluded] <- 0
  x[v == unresolved] <- fill

  # Guard against the scenario-label error found in D08.
  stopifnot(
    all(x[v == 2] == as.numeric(included == 2)),
    all(x[v == 4] == as.numeric(included == 4))
  )

  hazard <- r
  values(hazard) <- x

  values(
    fire_exp(hazard, t_dist = 500),
    mat = FALSE
  )
}

scenario <- function(included) {
  cat("Calculating scenario with C-", included,
      " included\n", sep = "")

  e24_0 <- calculate(r24, fuel24, 105, included, 0)
  e24_1 <- calculate(r24, fuel24, 105, included, 1)

  e26_0 <- calculate(r26, fuel26, 13, included, 0)
  e26_1 <- calculate(r26, fuel26, 13, included, 1)

  list(
    baseline = e26_0 - e24_0,
    lower = e26_0 - e24_1,
    upper = e26_1 - e24_0
  )
}

A <- scenario(2)
B <- scenario(4)

valid <- is.finite(A$lower) &
         is.finite(A$upper) &
         is.finite(B$lower) &
         is.finite(B$upper)

stopifnot(
  sum(valid) == 36100,
  identical(is.finite(A$lower), valid),
  identical(is.finite(A$upper), valid),
  identical(is.finite(B$lower), valid),
  identical(is.finite(B$upper), valid),
  all(A$lower[valid] <= A$upper[valid] + 1e-8),
  all(B$lower[valid] <= B$upper[valid] + 1e-8)
)

tol <- 1e-6

# Both scenarios must have definite, opposing signs
# across their entire unresolved-category bounds.

opposite <- valid & (
  (A$lower > tol & B$upper < -tol) |
  (A$upper < -tol & B$lower > tol)
)

stopifnot(
  sum(opposite) == 19436
)

# -----------------------------------------
# Reconcile with maintained D08 global table
# -----------------------------------------

global <- read.csv(
  "outputs/tables/d08_conifer_sensitivity_global.csv"
)

stopifnot(
  identical(
    as.character(global$scenario),
    c("A_C2_included", "B_C4_included")
  )
)

for (i in seq_len(2)) {
  result <- if (i == 1) A else B

  stopifnot(
    abs(
      mean(result$baseline[valid]) -
      global$mean_fixed_zero[i]
    ) < 1e-7,

    abs(
      mean(result$lower[valid]) -
      global$mean_delta_lower[i]
    ) < 1e-7,

    abs(
      mean(result$upper[valid]) -
      global$mean_delta_upper[i]
    ) < 1e-7,

    sum(result$lower[valid] > tol) ==
      global$definitely_positive_cells[i],

    sum(result$upper[valid] < -tol) ==
      global$definitely_negative_cells[i],

    sum(
      result$lower[valid] <= tol &
      result$upper[valid] >= -tol
    ) == global$zero_in_interval_cells[i]
  )
}

# -----------------------------------------
# Reconcile selected D07/D08 neighbourhoods
# -----------------------------------------

local <- read.csv(
  "outputs/tables/d08_conifer_sensitivity_local.csv"
)

cells <- seq_len(ncell(r24))
row_id <- ((cells - 1L) %/% ncol(r24)) + 1L
col_id <- ((cells - 1L) %% ncol(r24)) + 1L

block_id <- (
  ((row_id - 1L) %/% 20L) * 10L +
  ((col_id - 1L) %/% 20L) + 1L
)

for (i in seq_len(nrow(local))) {
  ix <- valid & block_id == local$block_id[i]

  stopifnot(
    sum(ix) == 400,
    abs(mean(A$lower[ix]) - local$A_mean_lower[i]) < 1e-7,
    abs(mean(A$upper[ix]) - local$A_mean_upper[i]) < 1e-7,
    abs(mean(B$lower[ix]) - local$B_mean_lower[i]) < 1e-7,
    abs(mean(B$upper[ix]) - local$B_mean_upper[i]) < 1e-7,
    sum(opposite[ix]) == local$robust_opposite_cells[i]
  )
}

cat("\nD08 global reconciliation: PASSED\n")
cat("D08 local reconciliation: PASSED\n")

# -----------------------------------------
# Export spatial products
# -----------------------------------------

output_dir <- "data/processed/visualization"

dir.create(
  output_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

make_raster <- function(x, layer_name) {
  result <- r26
  values(result) <- x
  names(result) <- layer_name
  result
}

products <- list(
  d09_scenario_A_delta_lower_500m =
    make_raster(A$lower, "A_delta_lower"),

  d09_scenario_A_delta_upper_500m =
    make_raster(A$upper, "A_delta_upper"),

  d09_scenario_B_delta_lower_500m =
    make_raster(B$lower, "B_delta_lower"),

  d09_scenario_B_delta_upper_500m =
    make_raster(B$upper, "B_delta_upper")
)

for (name in names(products)) {
  path <- file.path(output_dir, paste0(name, ".tif"))

  writeRaster(
    products[[name]],
    path,
    overwrite = TRUE,
    datatype = "FLT4S",
    NAflag = -9999
  )

  cat("Exported:", path, "\n")
}

# 1 = robust opposing signs
# 0 = no robust opposing signs
# NA = outside valid assessment region

classification <- rep(NA_integer_, ncell(r26))
classification[valid] <- as.integer(opposite[valid])

class_raster <- make_raster(
  classification,
  "robust_opposing_sign"
)

class_path <- file.path(
  output_dir,
  "d09_robust_opposing_sign_500m.tif"
)

writeRaster(
  class_raster,
  class_path,
  overwrite = TRUE,
  datatype = "INT1U"
)

cat("Exported:", class_path, "\n")

cat("\n=== Verified results ===\n")
cat("Valid cells:", sum(valid), "\n")

cat("Scenario A mean lower:", mean(A$lower[valid]), "\n")
cat("Scenario A mean upper:", mean(A$upper[valid]), "\n")

cat("Scenario B mean lower:", mean(B$lower[valid]), "\n")
cat("Scenario B mean upper:", mean(B$upper[valid]), "\n")

cat("Robust opposing-sign cells:", sum(opposite), "\n")
cat(
  "Robust opposing-sign share (%):",
  round(100 * mean(opposite[valid]), 2),
  "\n"
)

cat("\nD09.5 export: PASSED\n")
cat("No maps rendered.\n")
