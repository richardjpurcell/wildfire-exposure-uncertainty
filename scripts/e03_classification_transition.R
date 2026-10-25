# E03: Directional classification transitions
# Controlled synthetic experiment.

library(terra)
library(fireexposuR)

source("R/directional_support.R")

template <- rast(
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
  crs = crs(template)
)

x <- init(template, "x")
y <- init(template, "y")

distance <- sqrt(
  (x - 10000)^2 +
  (y - 10000)^2
)

radii <- c(3550, 3600, 3650)

results <- list()

for (radius in radii) {

  exposure <- ifel(
    distance <= radius,
    0.75,
    0.40
  )

  names(exposure) <- "exposure"

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

  comparison$radius <- radius

  results[[as.character(radius)]] <- comparison
}

combined <- do.call(rbind, results)

middle <- combined[combined$seg == "seg2", ]

summary <- aggregate(
  cbind(
    high_fraction,
    decision_margin,
    viable
  ) ~ radius,
  data = middle,
  FUN = mean
)

names(summary)[names(summary) == "viable"] <-
  "viable_proportion"

cat("E03: Classification transition\n")

cat("\nMiddle-segment summary:\n")
print(summary, row.names = FALSE, digits = 5)

cat("\nMiddle-segment viability counts:\n")
print(table(middle$radius, middle$viable))

cat("\nSelected bearings:\n")
print(
  middle[
    middle$deg %in% c(60, 90, 180, 270),
    c(
      "radius",
      "deg",
      "high_fraction",
      "decision_margin",
      "viable"
    )
  ],
  row.names = FALSE,
  digits = 5
)

stopifnot(
  nrow(combined) == 324,
  all(combined$high_fraction >= 0),
  all(combined$high_fraction <= 1.000001)
)

cat("\nE03 initial transition test: PASSED\n")

# E03 cross-scenario consistency checks

ordered <- combined[
  order(combined$deg, combined$seg, combined$radius),
]

by_segment <- split(
  ordered,
  interaction(ordered$deg, ordered$seg, drop = TRUE)
)

support_monotonic <- vapply(
  by_segment,
  function(x) all(diff(x$high_fraction) >= -1e-8),
  logical(1)
)

viability_monotonic <- vapply(
  by_segment,
  function(x) all(diff(x$viable) >= 0),
  logical(1)
)

first_viable <- vapply(
  by_segment,
  function(x) {
    candidates <- x$radius[x$viable == 1]
    if (length(candidates) == 0) NA_real_
    else min(candidates)
  },
  numeric(1)
)

cat("\nE03 transition consistency:\n")
cat("Support monotonic:",
    sum(support_monotonic), "of", length(support_monotonic), "\n")
cat("Classification monotonic:",
    sum(viability_monotonic), "of", length(viability_monotonic), "\n")

cat("\nFirst tested viable radius (all segments):\n")
print(table(first_viable, useNA = "ifany"))

stopifnot(
  all(support_monotonic),
  all(viability_monotonic)
)

cat("\nE03 transition consistency: PASSED\n")
