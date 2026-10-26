# D10.13 — Westwood Hills threshold-grid stability
#
# 36 bearings x 3 segments x 72 threshold combinations.
# Viable fraction is sensitivity within the tested grid,
# not a probability of correctness or operational safety.

library(terra)
library(sf)
library(fireexposuR)

source("R/directional_support.R")

cat("\n=== D10.13: DIRECTIONAL THRESHOLD STABILITY ===\n")

exposure <- rast(
  "data/processed/visualization/d09_reference_exposure_2026_500m.tif"
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
stopifnot(same.crs(exposure, point))

baseline <- read.csv(
  "outputs/tables/d10_integrated_directional_assessment.csv",
  stringsAsFactors = FALSE
)

stopifnot(
  nrow(baseline) == 108,
  sum(baseline$viable == 1) == 42,
  all(baseline$viable == baseline$reconstructed_viable)
)

grid <- expand.grid(
  thresh_exp = seq(0.40, 0.80, by = 0.05),
  thresh_viable = seq(0.60, 0.95, by = 0.05)
)

stopifnot(nrow(grid) == 72)

evaluations <- vector("list", nrow(grid))

for (i in seq_len(nrow(grid))) {

  te <- grid$thresh_exp[i]
  tv <- grid$thresh_viable[i]

  transects <- fire_exp_dir(
    exposure = exposure,
    value = point,
    t_lengths = c(2000, 2000, 2000),
    interval = 10,
    thresh_exp = te,
    thresh_viable = tv
  )

  observed <- as.data.frame(transects, geom = NULL)

  support <- directional_support(
    exposure = exposure,
    transects = transects,
    thresh_exp = te,
    thresh_viable = tv
  )

  compared <- merge(
    observed[, c("deg", "seg", "viable")],
    support[, c("deg", "seg", "reconstructed_viable")],
    by = c("deg", "seg")
  )

  stopifnot(
    nrow(compared) == 108,
    !anyDuplicated(compared[, c("deg", "seg")]),
    all(compared$viable == compared$reconstructed_viable)
  )

  compared$setting_id <- i
  compared$thresh_exp <- te
  compared$thresh_viable <- tv

  evaluations[[i]] <- compared

  if (i %% 12 == 0) {
    cat("Verified settings:", i, "of 72\n")
  }
}

all_results <- do.call(rbind, evaluations)

stopifnot(
  nrow(all_results) == 7776,
  all(all_results$viable %in% c(0, 1))
)

# Summarize viable counts by unique directional segment.

summary <- aggregate(
  viable ~ deg + seg,
  data = all_results,
  FUN = sum
)

names(summary)[3] <- "viable_count"

summary$tested_settings <- nrow(grid)
summary$viable_fraction <-
  summary$viable_count / summary$tested_settings

# Attach the already verified baseline classification.

summary <- merge(
  summary,
  baseline[, c("deg", "seg", "viable")],
  by = c("deg", "seg")
)

names(summary)[names(summary) == "viable"] <-
  "baseline_viable"

summary <- summary[
  order(
    summary$deg,
    match(summary$seg, c("seg1", "seg2", "seg3"))
  ),
]

rownames(summary) <- NULL

stopifnot(
  nrow(summary) == 108,
  all(summary$viable_count >= 0),
  all(summary$viable_count <= 72),
  all(summary$viable_fraction >= 0),
  all(summary$viable_fraction <= 1)
)

# The baseline 0.60 / 0.80 setting must reproduce
# the already verified 42 viable classifications.

baseline_setting <- all_results[
  abs(all_results$thresh_exp - 0.60) < 1e-8 &
  abs(all_results$thresh_viable - 0.80) < 1e-8,
]

stopifnot(
  nrow(baseline_setting) == 108,
  sum(baseline_setting$viable == 1) == 42
)

baseline_check <- merge(
  baseline_setting[, c("deg", "seg", "viable")],
  baseline[, c("deg", "seg", "viable")],
  by = c("deg", "seg"),
  suffixes = c(".grid", ".baseline")
)

stopifnot(
  nrow(baseline_check) == 108,
  all(
    baseline_check$viable.grid ==
    baseline_check$viable.baseline
  )
)

output <- "outputs/tables/d10_threshold_stability.csv"

dir.create(
  dirname(output),
  recursive = TRUE,
  showWarnings = FALSE
)

write.csv(summary, output, row.names = FALSE)

cat("\n=== STABILITY SUMMARY ===\n")
print(summary(summary$viable_fraction))

cat("\n=== SEGMENTS BY STABILITY ===\n")
cat(
  "Never viable:",
  sum(summary$viable_count == 0), "\n"
)
cat(
  "Always viable:",
  sum(summary$viable_count == 72), "\n"
)
cat(
  "Variable:",
  sum(summary$viable_count > 0 &
      summary$viable_count < 72), "\n"
)

cat("\n=== BY DISTANCE SEGMENT ===\n")
print(
  aggregate(
    viable_fraction ~ seg,
    data = summary,
    FUN = mean
  )
)

cat("\nBaseline agreement: 108 of 108\n")
cat("Evaluations:", nrow(all_results), "\n")
cat("Output:", output, "\n")
cat("\nD10.13 threshold stability: PASSED\n")
