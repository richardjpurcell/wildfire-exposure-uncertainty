# E07: Integrated synthetic exposure and evidence landscape
# Initial step: construct and verify the landscape.

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

# E05 baseline radial gradient.
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

# Introduce missing evidence southwest of centre.
missing_region <- (
  x >= 6000 & x < 10000 &
  y >= 6000 & y < 10000
)

exposure <- ifel(
  missing_region,
  NA_real_,
  exposure
)

names(exposure) <- "exposure"

available <- !is.na(exposure)

cat("E07: Integrated synthetic landscape\n")

cat("\nRaster dimensions:\n")
print(dim(exposure))

cat("\nEvidence availability:\n")
available_cells <- global(available, "sum", na.rm = TRUE)[1, 1]

cat("Available cells:", available_cells, "\n")
cat("Missing cells:", ncell(exposure) - available_cells, "\n")
cat("Coverage fraction:", available_cells / ncell(exposure), "\n")

cat("\nAvailable exposure summary:\n")
print(global(exposure, c("min", "mean", "max"), na.rm = TRUE))

stopifnot(
  ncell(exposure) == 40000,
  available_cells == 38400,
  anyNA(values(exposure)),
  global(exposure, "max", na.rm = TRUE)[1, 1] <= 0.90
)

cat("\nE07 landscape construction: PASSED\n")

# E07 baseline directional assessment

library(fireexposuR)

source("R/directional_support.R")
source("R/directional_coverage.R")
source("R/directional_assessment.R")

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

assessment <- directional_assessment(
  exposure = exposure,
  transects = directions,
  thresh_exp = 0.60,
  thresh_viable = 0.80
)

original <- as.data.frame(directions)

comparison <- merge(
  original[, c("deg", "seg", "viable")],
  assessment,
  by = c("deg", "seg")
)

stopifnot(
  nrow(comparison) == 108,
  all(comparison$viable ==
      comparison$reconstructed_viable)
)

cat("\nE07 baseline directional assessment:\n")

cat("\nClassification counts:\n")
print(table(comparison$seg, comparison$viable))

cat("\nEvidence coverage summary:\n")
print(summary(comparison$coverage_fraction))

cat("\nEvidence status counts:\n")
print(table(comparison$evidence_status))

cat("\nSelected directional measurements:\n")

selected <- comparison[
  comparison$deg %in% c(45, 90, 180, 225, 270),
  c(
    "deg",
    "seg",
    "high_fraction",
    "coverage_fraction",
    "observed_support",
    "reconstructed_viable",
    "evidence_status"
  )
]

print(
  selected[order(selected$deg, selected$seg), ],
  row.names = FALSE,
  digits = 5
)

cat("\nE07 baseline assessment: PASSED\n")

# E07 diagnostic: near-zero evidence coverage

near_zero <- assessment[
  assessment$coverage_fraction > 0 &
    assessment$coverage_fraction < 0.001,
  c(
    "deg",
    "seg",
    "length_m",
    "high_length_m",
    "observed_length_m",
    "coverage_fraction",
    "observed_support",
    "evidence_status"
  )
]

cat("\nE07 near-zero coverage diagnostic:\n")
cat("Segments:", nrow(near_zero), "\n")

print(
  near_zero[
    order(near_zero$deg, near_zero$seg),
  ],
  row.names = FALSE,
  digits = 10
)

cat("\nE07 near-zero coverage diagnostic: COMPLETE\n")

# E07: Verify negligible coverage is not treated as observed support.

negligible <- assessment[
  assessment$coverage_fraction > 0 &
    assessment$coverage_fraction <= 1e-8,
]

cat("\nE07 negligible-coverage verification:\n")
cat("Affected segments:", nrow(negligible), "\n")

cat(
  "Undefined observed-only support:",
  sum(is.na(negligible$observed_support)),
  "of",
  nrow(negligible),
  "\n"
)

stopifnot(
  nrow(negligible) == 9,
  all(is.na(negligible$observed_support)),
  all(negligible$evidence_status == "missing"),
  all(negligible$reconstructed_viable == 0)
)

cat("\nE07 negligible-coverage correction: PASSED\n")

# E07: Threshold-grid viability on the partially observed landscape

threshold_grid <- expand.grid(
  thresh_exp = seq(0.40, 0.80, by = 0.05),
  thresh_viable = seq(0.60, 0.95, by = 0.05)
)

grid_results <- vector("list", nrow(threshold_grid))

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

  grid_results[[i]] <- data.frame(
    deg = comparison_i$deg,
    seg = comparison_i$seg,
    thresh_exp = te,
    thresh_viable = tv,
    viable = comparison_i$viable
  )
}

all_grid <- do.call(rbind, grid_results)

viable_counts <- aggregate(
  viable ~ deg + seg,
  data = all_grid,
  FUN = sum
)

names(viable_counts)[
  names(viable_counts) == "viable"
] <- "viable_count"

viable_counts$viable_fraction <-
  viable_counts$viable_count / nrow(threshold_grid)

# Attach the baseline evidence-coverage measurements.
integrated <- merge(
  assessment,
  viable_counts,
  by = c("deg", "seg")
)

cat("\nE07 integrated threshold-grid results:\n")
cat("Threshold combinations:", nrow(threshold_grid), "\n")
cat("Directional segments:", nrow(integrated), "\n")

cat("\nViable fraction by segment group:\n")
print(
  aggregate(
    viable_fraction ~ seg,
    data = integrated,
    FUN = function(z) {
      c(min = min(z), mean = mean(z), max = max(z))
    }
  ),
  row.names = FALSE,
  digits = 5
)

cat("\nThreshold-grid viability by evidence status:\n")
print(
  aggregate(
    viable_fraction ~ evidence_status,
    data = integrated,
    FUN = function(z) {
      c(min = min(z), mean = mean(z), max = max(z))
    }
  ),
  row.names = FALSE,
  digits = 5
)

cat("\nSelected western segments:\n")
print(
  integrated[
    integrated$deg == 270,
    c(
      "deg", "seg",
      "coverage_fraction",
      "evidence_status",
      "reconstructed_viable",
      "viable_count",
      "viable_fraction"
    )
  ],
  row.names = FALSE,
  digits = 5
)

stopifnot(
  nrow(threshold_grid) == 72,
  nrow(all_grid) == 7776,
  nrow(integrated) == 108,
  all(integrated$viable_count >= 0),
  all(integrated$viable_count <= 72)
)

cat("\nE07 integrated threshold grid: PASSED\n")

# E07: Inspect all partially covered directional segments.

partial_segments <- integrated[
  integrated$evidence_status == "partial",
  c(
    "deg",
    "seg",
    "length_m",
    "observed_length_m",
    "coverage_fraction",
    "high_fraction",
    "observed_support",
    "viable_fraction"
  )
]

partial_segments$missing_length_m <-
  partial_segments$length_m -
  partial_segments$observed_length_m

cat("\nE07 partial-coverage diagnostic:\n")

print(
  partial_segments[
    order(partial_segments$deg, partial_segments$seg),
  ],
  row.names = FALSE,
  digits = 7
)

cat("\nMissing length summary (metres):\n")
print(summary(partial_segments$missing_length_m))

stopifnot(nrow(partial_segments) == 9)

cat("\nE07 partial-coverage diagnostic: PASSED\n")

# E07: Export integrated directional assessment.

output_path <- "outputs/e07_integrated_directional_assessment.csv"

integrated <- integrated[
  order(integrated$deg, integrated$seg),
]

write.csv(
  integrated,
  file = output_path,
  row.names = FALSE,
  na = ""
)

cat("\nE07 integrated export:\n")
cat("File:", output_path, "\n")
cat("Rows:", nrow(integrated), "\n")
cat("Columns:", ncol(integrated), "\n")

stopifnot(
  file.exists(output_path),
  nrow(read.csv(output_path)) == 108,
  all(c(
    "deg",
    "seg",
    "high_fraction",
    "reconstructed_viable",
    "viable_count",
    "viable_fraction",
    "coverage_fraction",
    "observed_support",
    "evidence_status"
  ) %in% names(integrated))
)

cat("\nE07 integrated export: PASSED\n")
