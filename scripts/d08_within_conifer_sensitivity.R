# D08 — Within-conifer classification sensitivity
#
# Opposing hypothetical treatments:
# A: C-2 = 1, C-4 = 0
# B: C-2 = 0, C-4 = 1
#
# Other recognized vegetation = 1.
# Explicit water/non-fuel = 0.
# Unresolved categories = 0 or 1 to construct bounds.
#
# These are computational sensitivity scenarios,
# NOT validated wildfire transmission classifications.
#
# The original D08.14 labels were reversed.
# D08.16 independently verified the corrected assignments.

library(terra)
library(fireexposuR)

cat("\n=== D08: Maintained within-conifer sensitivity ===\n")

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

  # Verify actual assignments, not just scenario names.
  stopifnot(
    all(x[v == 2] == as.numeric(included == 2)),
    all(x[v == 4] == as.numeric(included == 4))
  )

  h <- r
  values(h) <- x

  values(fire_exp(h, t_dist = 500), mat = FALSE)
}

scenario <- function(included) {
  cat("Calculating C-", included, "-included scenario\n",
      sep = "")

  a <- calculate(r24, fuel24, 105, included, 0)
  b <- calculate(r24, fuel24, 105, included, 1)
  c <- calculate(r26, fuel26, 13, included, 0)
  d <- calculate(r26, fuel26, 13, included, 1)

  list(
    baseline = c - a,
    lower = c - b,
    upper = d - a
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
  all(A$lower[valid] <= A$upper[valid] + 1e-8),
  all(B$lower[valid] <= B$upper[valid] + 1e-8),
  abs(mean(A$baseline[valid]) - 0.07246814) < 1e-5,
  abs(mean(B$baseline[valid]) + 0.163813) < 1e-5
)

tol <- 1e-6

robust_opposite <- valid & (
  (A$lower > tol & B$upper < -tol) |
  (A$upper < -tol & B$lower > tol)
)

summarize <- function(name, x, ix) {
  data.frame(
    scenario = name,
    valid_cells = sum(ix),
    mean_fixed_zero = mean(x$baseline[ix]),
    mean_delta_lower = mean(x$lower[ix]),
    mean_delta_upper = mean(x$upper[ix]),
    definitely_positive_cells = sum(x$lower[ix] > tol),
    definitely_negative_cells = sum(x$upper[ix] < -tol),
    zero_in_interval_cells = sum(
      x$lower[ix] <= tol & x$upper[ix] >= -tol
    )
  )
}

global <- rbind(
  summarize("A_C2_included", A, valid),
  summarize("B_C4_included", B, valid)
)

stopifnot(
  global$mean_delta_lower[1] > 0,
  global$mean_delta_upper[2] < 0,
  sum(robust_opposite) == 19436
)

global$robust_opposing_sign_cells <- sum(robust_opposite)

cells <- seq_len(ncell(r24))
rr <- rowFromCell(r24, cells)
cc <- colFromCell(r24, cells)

block_id <- ((rr - 1) %/% 20) * 10 +
            ((cc - 1) %/% 20) + 1

ids <- c(35, 34, 25, 24, 44, 33)

local <- do.call(rbind, lapply(ids, function(id) {
  ix <- block_id == id & valid

  stopifnot(sum(ix) == 400)

  data.frame(
    block_id = id,
    valid_cells = sum(ix),
    A_mean_lower = mean(A$lower[ix]),
    A_mean_upper = mean(A$upper[ix]),
    B_mean_lower = mean(B$lower[ix]),
    B_mean_upper = mean(B$upper[ix]),
    robust_opposite_cells = sum(robust_opposite[ix])
  )
}))

# Validate against D08.16 before creating outputs.

stopifnot(
  abs(global$mean_delta_lower[1] - 0.0488393) < 1e-5,
  abs(global$mean_delta_upper[1] - 0.107220) < 1e-5,
  abs(global$mean_delta_lower[2] + 0.1874418) < 1e-5,
  abs(global$mean_delta_upper[2] + 0.129061) < 1e-5,
  local$robust_opposite_cells[local$block_id == 35] == 187,
  local$robust_opposite_cells[local$block_id == 44] == 232
)

dir.create(
  "outputs/tables",
  recursive = TRUE,
  showWarnings = FALSE
)

write.csv(
  global,
  "outputs/tables/d08_conifer_sensitivity_global.csv",
  row.names = FALSE
)

write.csv(
  local,
  "outputs/tables/d08_conifer_sensitivity_local.csv",
  row.names = FALSE
)

cat("\n=== Regional results ===\n")
print(global, row.names = FALSE, digits = 6)

cat("\n=== Local results ===\n")
print(local, row.names = FALSE, digits = 6)

cat("\nD08 within-conifer reproducibility: PASSED\n")
cat("Two CSV files written. No maps created.\n")
