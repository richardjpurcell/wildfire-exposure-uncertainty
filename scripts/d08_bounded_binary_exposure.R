# D08 — Bounded binary exposure comparison
#
# Compare 2024 and 2026 national FBP representations.
# This is an experimental vegetation/non-fuel rule,
# NOT a validated 500 m fire-transmission classification.
#
# Unresolved classes are assigned 0 and 1 in separate
# scenarios, producing deterministic sensitivity bounds.
#
# No maps or raster outputs are written.

library(terra)
library(fireexposuR)

cat("\n=== D08: Bounded binary exposure ===\n")

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

make_status <- function(r, fuel, unresolved) {
  v <- values(r, mat = FALSE)
  stopifnot(
    !anyNA(v),
    all(v %in% c(fuel, nonfuel, unresolved))
  )

  s <- rep(NA_real_, length(v))
  s[v %in% fuel] <- 1
  s[v %in% nonfuel] <- 0
  s
}

s24 <- make_status(r24, fuel24, 105)
s26 <- make_status(r26, fuel26, 13)

stopifnot(
  sum(is.na(s24)) == 853,
  sum(is.na(s26)) == 1326,
  sum(!is.na(s24) & !is.na(s26) & s24 != s26) == 3089
)

make_hazard <- function(template, status, fill) {
  h <- template
  x <- status
  x[is.na(x)] <- fill
  values(h) <- x
  h
}

cat("Computing four 500 m exposure surfaces...\n")

exposure <- function(r, status, fill) {
  values(
    fire_exp(
      make_hazard(r, status, fill),
      t_dist = 500
    ),
    mat = FALSE
  )
}

a <- exposure(r24, s24, 0)
b <- exposure(r24, s24, 1)
c <- exposure(r26, s26, 0)
d <- exposure(r26, s26, 1)

valid <- is.finite(a) & is.finite(b) &
         is.finite(c) & is.finite(d)

stopifnot(
  sum(valid) == 36100,
  all(a[valid] <= b[valid] + 1e-6),
  all(c[valid] <= d[valid] + 1e-6)
)

delta_low <- c - b
delta_high <- d - a

stopifnot(
  all(delta_low[valid] <= delta_high[valid] + 1e-6)
)

positive <- valid & delta_low > 1e-6
negative <- valid & delta_high < -1e-6
indeterminate <- valid & !positive & !negative

stopifnot(
  sum(positive) + sum(negative) +
    sum(indeterminate) == 36100
)

# Global summaries, each with the same spatial support.

global <- data.frame(
  metric = c(
    "valid_cells",
    "mean_2024_lower",
    "mean_2024_upper",
    "mean_2026_lower",
    "mean_2026_upper",
    "mean_interval_width_2024",
    "mean_interval_width_2026",
    "mean_delta_lower",
    "mean_delta_upper",
    "definitely_positive_cells",
    "definitely_negative_cells",
    "zero_in_difference_interval_cells"
  ),
  value = c(
    sum(valid),
    mean(a[valid]),
    mean(b[valid]),
    mean(c[valid]),
    mean(d[valid]),
    mean(b[valid] - a[valid]),
    mean(d[valid] - c[valid]),
    mean(delta_low[valid]),
    mean(delta_high[valid]),
    sum(positive),
    sum(negative),
    sum(indeterminate)
  )
)

# Local summaries using the established 2 km blocks.

cells <- seq_len(ncell(r24))
rr <- rowFromCell(r24, cells)
cc <- colFromCell(r24, cells)

block_id <- ((rr - 1) %/% 20) * 10 +
            ((cc - 1) %/% 20) + 1

ids <- c(35, 34, 25, 24, 44, 33)

local <- do.call(rbind, lapply(ids, function(id) {
  ix <- which(block_id == id & valid)

  stopifnot(length(ix) == 400)

  data.frame(
    block_id = id,
    valid_cells = length(ix),
    mean_2024_lower = mean(a[ix]),
    mean_2024_upper = mean(b[ix]),
    mean_2026_lower = mean(c[ix]),
    mean_2026_upper = mean(d[ix]),
    mean_delta_lower = mean(delta_low[ix]),
    mean_delta_upper = mean(delta_high[ix]),
    definitely_positive_cells = sum(positive[ix]),
    definitely_negative_cells = sum(negative[ix]),
    zero_in_interval_cells = sum(indeterminate[ix])
  )
}))

# Validate against independently observed diagnostics.

stopifnot(
  abs(mean(a[valid]) - 0.7624) < 0.001,
  abs(mean(b[valid]) - 0.7861) < 0.001,
  abs(mean(c[valid]) - 0.7124) < 0.001,
  abs(mean(d[valid]) - 0.7472) < 0.001,
  abs(mean(delta_low[valid]) + 0.0736) < 0.001,
  abs(mean(delta_high[valid]) + 0.0152) < 0.001,
  sum(positive) == 3891,
  sum(negative) == 20075,
  sum(indeterminate) == 12134
)

check <- function(id, field, expected, tolerance = 0.001) {
  actual <- local[local$block_id == id, field]
  stopifnot(
    length(actual) == 1,
    abs(actual - expected) < tolerance
  )
}

check(35, "mean_delta_lower", -0.24209)
check(35, "mean_delta_upper", 0.04384)
check(34, "mean_delta_upper", -0.05337)
check(25, "mean_delta_lower", -0.51594)
check(25, "mean_delta_upper", 0.21184)
check(24, "mean_delta_upper", -0.03547)

check(35, "definitely_negative_cells", 108, 0.01)
check(34, "definitely_negative_cells", 353, 0.01)
check(25, "zero_in_interval_cells", 283, 0.01)

# All validation occurs before output creation.

dir.create(
  "outputs/tables",
  recursive = TRUE,
  showWarnings = FALSE
)

write.csv(
  global,
  "outputs/tables/d08_bounded_exposure_global.csv",
  row.names = FALSE
)

write.csv(
  local,
  "outputs/tables/d08_bounded_exposure_local.csv",
  row.names = FALSE
)

cat("\n=== Global results ===\n")
print(global, row.names = FALSE, digits = 5)

cat("\n=== Local results ===\n")
print(local, row.names = FALSE, digits = 5)

cat("\nD08 bounded exposure reproducibility: PASSED\n")
cat("Two CSV files written. No maps created.\n")
