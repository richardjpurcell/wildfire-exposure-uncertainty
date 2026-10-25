# E05: Directional variation in a heterogeneous exposure surface
# Initial step: construct and verify the synthetic landscape.

library(terra)

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
y <- init(template, "y")

distance <- sqrt(
  (x - 10000)^2 +
  (y - 10000)^2
)

# Same baseline radial gradient as E04.
baseline <- clamp(
  0.90 - 0.0001 * distance,
  lower = 0.20,
  upper = 0.90,
  values = TRUE
)

# Controlled eastern exposure increment.
exposure <- ifel(
  x >= 10000,
  baseline + 0.10,
  baseline
)

exposure <- clamp(
  exposure,
  lower = 0.20,
  upper = 0.90,
  values = TRUE
)

names(exposure) <- "exposure"

# Compare equally distant points east and west.
east_point <- vect(
  "POINT (13000 10000)",
  crs = crs(exposure)
)

west_point <- vect(
  "POINT (7000 10000)",
  crs = crs(exposure)
)

east_value <- extract(exposure, east_point)$exposure
west_value <- extract(exposure, west_point)$exposure

cat("E05: Heterogeneous synthetic exposure surface\n")

cat("\nExposure summary:\n")
print(global(exposure, c("min", "mean", "max"), na.rm = TRUE))

cat("\nEqual-distance comparison:\n")
cat("East exposure:", east_value, "\n")
cat("West exposure:", west_value, "\n")
cat("Difference:", east_value - west_value, "\n")

stopifnot(
  ncell(exposure) == 40000,
  east_value > west_value,
  abs((east_value - west_value) - 0.10) < 0.02,
  global(exposure, "max", na.rm = TRUE)[1, 1] <= 0.90
)

cat("\nE05 exposure surface: PASSED\n")

# E05 initial directional comparison

library(fireexposuR)

source("R/directional_support.R")

point <- vect(
  "POINT (10000 10000)",
  crs = crs(exposure)
)

directions <- fire_exp_dir(
  exposure = exposure,
  value = point,
  t_lengths = c(2000, 2000, 2000),
  interval = 10,
  thresh_exp = 0.60,
  thresh_viable = 0.80
)

support <- directional_support(
  exposure = exposure,
  transects = directions,
  thresh_exp = 0.60,
  thresh_viable = 0.80
)

original <- as.data.frame(directions)

comparison <- merge(
  original[, c("deg", "seg", "viable")],
  support,
  by = c("deg", "seg")
)

stopifnot(
  nrow(comparison) == 108,
  all(comparison$viable ==
      comparison$reconstructed_viable)
)

cat("\nE05 directional support by bearing:\n")

selected <- comparison[
  comparison$deg %in% c(90, 270),
  c("deg", "seg", "high_fraction",
    "decision_margin", "viable")
]

print(
  selected[order(selected$deg, selected$seg), ],
  row.names = FALSE,
  digits = 5
)

cat("\nClassification counts by segment:\n")
print(table(comparison$seg, comparison$viable))

# Test the expected east-west distinction.
east <- comparison[comparison$deg == 90, ]
west <- comparison[comparison$deg == 270, ]

east <- east[order(east$seg), ]
west <- west[order(west$seg), ]

stopifnot(
  nrow(east) == 3,
  nrow(west) == 3,
  all(east$seg == west$seg),
  all(east$high_fraction >=
      west$high_fraction - 1e-8),
  any(east$high_fraction >
      west$high_fraction + 0.01)
)

cat("\nE05 directional asymmetry test: PASSED\n")

# E05 threshold-grid directional comparison

threshold_grid <- expand.grid(
  thresh_exp = seq(0.40, 0.80, by = 0.05),
  thresh_viable = seq(0.60, 0.95, by = 0.05)
)

grid_segments <- vector("list", nrow(threshold_grid))

for (i in seq_len(nrow(threshold_grid))) {

  te <- threshold_grid$thresh_exp[i]
  tv <- threshold_grid$thresh_viable[i]

  directions_i <- fire_exp_dir(
    exposure = exposure,
    value = point,
    t_lengths = c(2000, 2000, 2000),
    interval = 10,
    thresh_exp = te,
    thresh_viable = tv
  )

  support_i <- directional_support(
    exposure = exposure,
    transects = directions_i,
    thresh_exp = te,
    thresh_viable = tv
  )

  original_i <- as.data.frame(directions_i)

  comparison_i <- merge(
    original_i[, c("deg", "seg", "viable")],
    support_i,
    by = c("deg", "seg")
  )

  stopifnot(
    nrow(comparison_i) == 108,
    all(comparison_i$viable ==
        comparison_i$reconstructed_viable)
  )

  comparison_i$thresh_exp <- te
  comparison_i$thresh_viable <- tv

  grid_segments[[i]] <- comparison_i
}

all_segments <- do.call(rbind, grid_segments)

counts <- aggregate(
  viable ~ deg + seg,
  data = all_segments,
  FUN = sum
)

names(counts)[names(counts) == "viable"] <- "viable_count"

counts$viable_fraction <- counts$viable_count / 72

selected_counts <- counts[
  counts$deg %in% c(90, 270) &
    counts$seg == "seg2",
]

cat("\nE05 threshold-grid results, middle segment:\n")
print(
  selected_counts[
    order(selected_counts$deg),
  ],
  row.names = FALSE,
  digits = 5
)

cat("\nViable-fraction ranges by segment:\n")
print(
  aggregate(
    viable_fraction ~ seg,
    data = counts,
    FUN = function(x) {
      c(min = min(x), mean = mean(x), max = max(x))
    }
  ),
  row.names = FALSE,
  digits = 5
)

stopifnot(
  nrow(all_segments) == 7776,
  nrow(counts) == 108,
  all(counts$viable_count >= 0),
  all(counts$viable_count <= 72)
)

cat("\nE05 threshold-grid comparison: PASSED\n")

# E05 paired east-west threshold consistency

middle_pair <- all_segments[
  all_segments$seg == "seg2" &
    all_segments$deg %in% c(90, 270),
  c("deg", "thresh_exp", "thresh_viable",
    "high_fraction", "viable")
]

east_grid <- middle_pair[middle_pair$deg == 90, ]
west_grid <- middle_pair[middle_pair$deg == 270, ]

paired_grid <- merge(
  east_grid,
  west_grid,
  by = c("thresh_exp", "thresh_viable"),
  suffixes = c("_east", "_west")
)

paired_grid$support_difference <-
  paired_grid$high_fraction_east -
  paired_grid$high_fraction_west

paired_grid$viability_difference <-
  paired_grid$viable_east -
  paired_grid$viable_west

cat("\nE05 paired east-west threshold comparison:\n")
cat("Threshold combinations:", nrow(paired_grid), "\n")

cat("East viable, west nonviable:",
    sum(paired_grid$viability_difference == 1), "\n")

cat("West viable, east nonviable:",
    sum(paired_grid$viability_difference == -1), "\n")

cat("Same classification:",
    sum(paired_grid$viability_difference == 0), "\n")

stopifnot(
  nrow(paired_grid) == 72,
  all(paired_grid$support_difference >= -1e-8),
  all(paired_grid$viability_difference >= 0),
  sum(paired_grid$viability_difference == 1) == 16
)

cat("\nE05 paired threshold consistency: PASSED\n")
