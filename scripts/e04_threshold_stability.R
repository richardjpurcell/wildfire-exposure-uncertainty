# E04: Two-dimensional threshold stability
# Initial step: construct a continuous synthetic exposure surface.

library(terra)
library(fireexposuR)

source("R/directional_support.R")

exposure <- rast(
  nrows = 200,
  ncols = 200,
  xmin = 0,
  xmax = 20000,
  ymin = 0,
  ymax = 20000,
  crs = "EPSG:3978"
)

point <- vect(
  "POINT (10000 10000)",
  crs = crs(exposure)
)

x <- init(exposure, "x")
y <- init(exposure, "y")

distance <- sqrt(
  (x - 10000)^2 +
  (y - 10000)^2
)

# Exposure decreases continuously with distance.
# The range is bounded between 0.20 and 0.90.
exposure <- 0.90 - 0.0001 * distance
exposure <- clamp(
  exposure,
  lower = 0.20,
  upper = 0.90,
  values = TRUE
)

names(exposure) <- "exposure"

cat("E04: Continuous synthetic exposure surface\n")

cat("\nRaster dimensions:\n")
print(dim(exposure))

cat("\nExposure summary:\n")
print(global(exposure, c("min", "mean", "max"), na.rm = TRUE))

cat("\nExposure near reference point:\n")
print(extract(exposure, point))

stopifnot(
  ncell(exposure) == 40000,
  global(exposure, "min", na.rm = TRUE)[1, 1] >= 0.20,
  global(exposure, "max", na.rm = TRUE)[1, 1] <= 0.90
)

cat("\nE04 exposure surface: PASSED\n")

# E04 preliminary two-dimensional threshold test

threshold_grid <- expand.grid(
  thresh_exp = seq(0.40, 0.80, by = 0.05),
  thresh_viable = seq(0.60, 0.95, by = 0.05)
)

grid_results <- list()
segment_results <- list()

for (i in seq_len(nrow(threshold_grid))) {

  te <- threshold_grid$thresh_exp[i]
  tv <- threshold_grid$thresh_viable[i]

  directions <- fire_exp_dir(
    exposure = exposure,
    value = point,
    t_lengths = c(2000, 2000, 2000),
    interval = 10,
    thresh_exp = te,
    thresh_viable = tv
  )

  support <- directional_support(
    exposure = exposure,
    transects = directions,
    thresh_exp = te,
    thresh_viable = tv
  )

  original <- as.data.frame(directions)

  comparison <- merge(
    original[, c("deg", "seg", "viable")],
    support,
    by = c("deg", "seg")
  )

  agreement <- sum(
    comparison$viable ==
      comparison$reconstructed_viable
  )

  stopifnot(
    nrow(comparison) == 108,
    agreement == 108,
    !anyNA(comparison$high_fraction)
  )

  segment_results[[i]] <- data.frame(
    thresh_exp = te,
    thresh_viable = tv,
    deg = comparison$deg,
    seg = comparison$seg,
    high_fraction = comparison$high_fraction,
    decision_margin = comparison$decision_margin,
    viable = comparison$viable
  )

  grid_results[[i]] <- data.frame(
    thresh_exp = te,
    thresh_viable = tv,
    mean_support = mean(comparison$high_fraction),
    viable_segments = sum(comparison$viable),
    agreement = agreement
  )
}

grid_summary <- do.call(rbind, grid_results)

cat("\nE04 preliminary threshold grid:\n")

print(
  grid_summary[
    order(
      grid_summary$thresh_exp,
      grid_summary$thresh_viable
    ),
  ],
  row.names = FALSE,
  digits = 5
)

stopifnot(
  nrow(grid_summary) == 72,
  all(grid_summary$agreement == 108)
)

cat("\nE04 preliminary threshold grid: PASSED\n")


# E04 segment-level threshold stability

all_segments <- do.call(rbind, segment_results)

stability <- aggregate(
  viable ~ deg + seg,
  data = all_segments,
  FUN = mean
)

names(stability)[names(stability) == "viable"] <-
  "viable_fraction"

cat("\nE04 threshold stability by segment group:\n")

print(
  aggregate(
    viable_fraction ~ seg,
    data = stability,
    FUN = function(x) {
      c(min = min(x), mean = mean(x), max = max(x))
    }
  ),
  row.names = FALSE,
  digits = 5
)

cat("\nThreshold stability distribution:\n")
print(summary(stability$viable_fraction))

stopifnot(
  nrow(all_segments) == 72 * 108,
  nrow(stability) == 108,
  all(stability$viable_fraction >= 0),
  all(stability$viable_fraction <= 1)
)

cat("\nE04 threshold stability summary: PASSED\n")

# E04 verification: stability as integer counts

counts <- aggregate(
  viable ~ deg + seg,
  data = all_segments,
  FUN = sum
)

names(counts)[names(counts) == "viable"] <- "viable_count"

counts <- merge(
  counts,
  stability,
  by = c("deg", "seg")
)

observations <- aggregate(
  viable ~ deg + seg,
  data = all_segments,
  FUN = length
)

names(observations)[names(observations) == "viable"] <- "n_tests"

counts <- merge(
  counts,
  observations,
  by = c("deg", "seg")
)

stopifnot(
  nrow(counts) == 108,
  all(counts$n_tests == 72),
  all(abs(
    counts$viable_fraction -
      counts$viable_count / counts$n_tests
  ) < 1e-10)
)

cat("\nE04 viable-count ranges by segment:\n")

print(
  aggregate(
    viable_count ~ seg,
    data = counts,
    FUN = function(x) {
      c(min = min(x), max = max(x))
    }
  ),
  row.names = FALSE
)

cat("\nE04 integer-count verification: PASSED\n")
