# E06: Missing evidence versus measured low exposure
# Initial diagnostic only; no modifications to package behaviour.

library(terra)
library(fireexposuR)

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

scenarios <- list(
  measured_low = 0.40,
  measured_high = 0.75,
  missing = NA_real_
)

cat("E06: Missing-evidence diagnostic\n")

for (scenario in names(scenarios)) {

  exposure <- template
  values(exposure) <- scenarios[[scenario]]
  names(exposure) <- "exposure"

  cat("\nScenario:", scenario, "\n")
  cat("Available raster cells:",
      global(!is.na(exposure), "sum")[1, 1],
      "of", ncell(exposure), "\n")

  result <- tryCatch(
    {
      directions <- fire_exp_dir(
        exposure = exposure,
        value = point,
        t_lengths = c(2000, 2000, 2000),
        interval = 10,
        thresh_exp = 0.60,
        thresh_viable = 0.80
      )

      output <- as.data.frame(directions)

      list(
        success = TRUE,
        n = nrow(output),
        counts = table(output$viable)
      )
    },
    error = function(e) {
      list(
        success = FALSE,
        message = conditionMessage(e)
      )
    }
  )

  if (result$success) {
    cat("Directional segments:", result$n, "\n")
    cat("Viability counts:\n")
    print(result$counts)
  } else {
    cat("Function returned an error:\n")
    cat(result$message, "\n")
  }
}

cat("\nE06 initial diagnostic: COMPLETE\n")

# E06: Partial missing-data diagnostic

cat("\nE06: Partial missing-data scenario\n")

x <- init(template, "x")

exposure_partial <- ifel(
  x < 10000,
  NA_real_,
  0.75
)

names(exposure_partial) <- "exposure"

cat(
  "Available raster cells:",
  global(!is.na(exposure_partial), "sum")[1, 1],
  "of", ncell(exposure_partial), "\n"
)

partial_result <- tryCatch(
  {
    directions <- fire_exp_dir(
      exposure = exposure_partial,
      value = point,
      t_lengths = c(2000, 2000, 2000),
      interval = 10,
      thresh_exp = 0.60,
      thresh_viable = 0.80
    )

    output <- as.data.frame(directions)

    cat("\nViability counts:\n")
    print(table(output$viable))

    cat("\nSelected bearings:\n")
    print(
      output[
        output$deg %in% c(90, 270),
        c("deg", "seg", "viable")
      ],
      row.names = FALSE
    )

    TRUE
  },
  error = function(e) {
    cat("\nFunction returned an error:\n")
    cat(conditionMessage(e), "\n")
    FALSE
  }
)

cat(
  "\nE06 partial-data function completed:",
  partial_result,
  "\n"
)

# E06: Paired low-exposure versus missing-evidence comparison

cat("\nE06: Paired evidence comparison\n")

exposure_measured <- ifel(
  x < 10000,
  0.40,
  0.75
)
names(exposure_measured) <- "exposure"

measured_directions <- fire_exp_dir(
  exposure = exposure_measured,
  value = point,
  t_lengths = c(2000, 2000, 2000),
  interval = 10,
  thresh_exp = 0.60,
  thresh_viable = 0.80
)

missing_directions <- fire_exp_dir(
  exposure = exposure_partial,
  value = point,
  t_lengths = c(2000, 2000, 2000),
  interval = 10,
  thresh_exp = 0.60,
  thresh_viable = 0.80
)

measured <- as.data.frame(measured_directions)
missing <- as.data.frame(missing_directions)

paired <- merge(
  measured[, c("deg", "seg", "viable")],
  missing[, c("deg", "seg", "viable")],
  by = c("deg", "seg"),
  suffixes = c("_measured", "_missing")
)

paired$agreement <-
  paired$viable_measured == paired$viable_missing

cat("\nClassification agreement:\n")
cat(sum(paired$agreement), "of", nrow(paired), "\n")

cat("\nWestern bearing comparison:\n")
print(
  paired[
    paired$deg == 270,
    c("deg", "seg", "viable_measured", "viable_missing")
  ],
  row.names = FALSE
)

stopifnot(
  nrow(paired) == 108,
  all(paired$agreement)
)

cat("\nE06 paired evidence comparison: PASSED\n")

# E06: Directional evidence coverage comparison

source("R/directional_coverage.R")

coverage_measured <- directional_coverage(
  exposure_measured,
  measured_directions
)

coverage_missing <- directional_coverage(
  exposure_partial,
  missing_directions
)

coverage_pair <- merge(
  coverage_measured[, c("deg", "seg", "coverage_fraction")],
  coverage_missing[, c("deg", "seg", "coverage_fraction")],
  by = c("deg", "seg"),
  suffixes = c("_measured", "_missing")
)

cat("\nE06 directional evidence coverage:\n")

selected_coverage <- coverage_pair[
  coverage_pair$deg %in% c(90, 270),
]

print(
  selected_coverage[
    order(selected_coverage$deg, selected_coverage$seg),
  ],
  row.names = FALSE,
  digits = 5
)

cat("\nMean coverage by bearing:\n")

print(
  aggregate(
    cbind(
      coverage_fraction_measured,
      coverage_fraction_missing
    ) ~ deg,
    data = coverage_pair[
      coverage_pair$deg %in% c(90, 270),
    ],
    FUN = mean
  ),
  row.names = FALSE,
  digits = 5
)

stopifnot(
  nrow(coverage_pair) == 108,
  !anyNA(coverage_pair),
  all(coverage_pair$coverage_fraction_measured >= -1e-8),
  all(coverage_pair$coverage_fraction_measured <= 1 + 1e-8),
  all(coverage_pair$coverage_fraction_missing >= -1e-8),
  all(coverage_pair$coverage_fraction_missing <= 1 + 1e-8)
)

cat("\nE06 coverage comparison: PASSED\n")

# E06: Verify the intended evidence-coverage distinction

east_coverage <- coverage_pair[
  coverage_pair$deg == 90,
]

west_coverage <- coverage_pair[
  coverage_pair$deg == 270,
]

stopifnot(
  nrow(east_coverage) == 3,
  nrow(west_coverage) == 3,
  all(abs(east_coverage$coverage_fraction_measured - 1) < 1e-8),
  all(abs(east_coverage$coverage_fraction_missing - 1) < 1e-8),
  all(abs(west_coverage$coverage_fraction_measured - 1) < 1e-8),
  all(abs(west_coverage$coverage_fraction_missing) < 1e-8),
  all(paired$agreement)
)

cat("\nE06 evidence distinction: PASSED\n")

# E06: Intermediate evidence-coverage test

exposure_strip <- exposure_measured

# Remove evidence between x = 9000 and x = 10000.
exposure_strip <- ifel(
  x >= 9000 & x < 10000,
  NA_real_,
  exposure_strip
)

names(exposure_strip) <- "exposure"

coverage_strip <- directional_coverage(
  exposure_strip,
  measured_directions
)

cat("\nE06 intermediate coverage, western bearings:\n")

print(
  coverage_strip[
    coverage_strip$deg %in% c(90, 270),
    c("deg", "seg", "coverage_fraction")
  ],
  row.names = FALSE,
  digits = 5
)

western_first <- coverage_strip[
  coverage_strip$deg == 270 &
    coverage_strip$seg == "seg1",
  "coverage_fraction"
]

stopifnot(
  length(western_first) == 1,
  western_first > 0,
  western_first < 1
)

cat("\nE06 intermediate coverage: PASSED\n")

# E06: Integrate support and evidence coverage

source("R/directional_support.R")

# The measured-low/high landscape provides the transect
# geometries used throughout this diagnostic.
support_strip <- directional_support(
  exposure = exposure_strip,
  transects = measured_directions,
  thresh_exp = 0.60,
  thresh_viable = 0.80
)

integrated <- merge(
  support_strip[, c(
    "deg", "seg", "high_fraction"
  )],
  coverage_strip[, c(
    "deg", "seg", "coverage_fraction"
  )],
  by = c("deg", "seg")
)

# High-exposure support among observed evidence.
# Leave undefined when no evidence is available.
integrated$observed_support <- ifelse(
  integrated$coverage_fraction > 0,
  integrated$high_fraction /
    integrated$coverage_fraction,
  NA_real_
)

cat("\nE06 integrated directional measurements:\n")

print(
  integrated[
    integrated$deg %in% c(90, 270),
    c(
      "deg",
      "seg",
      "high_fraction",
      "coverage_fraction",
      "observed_support"
    )
  ],
  row.names = FALSE,
  digits = 5
)

stopifnot(
  nrow(integrated) == 108,
  all(integrated$high_fraction >= 0),
  all(integrated$coverage_fraction >= 0),
  all(
    integrated$observed_support[
      !is.na(integrated$observed_support)
    ] <= 1 + 1e-6
  )
)

cat("\nE06 integrated measurements: PASSED\n")

# E06: Partial coverage with positive high-exposure support

# Preserve the measured-high eastern half.
# In the western half:
#   x = 9000..10000: missing evidence
#   x < 9000: measured high exposure

exposure_partial_high <- ifel(
  x >= 9000 & x < 10000,
  NA_real_,
  0.75
)

names(exposure_partial_high) <- "exposure"

support_partial_high <- directional_support(
  exposure = exposure_partial_high,
  transects = measured_directions,
  thresh_exp = 0.60,
  thresh_viable = 0.80
)

coverage_partial_high <- directional_coverage(
  exposure_partial_high,
  measured_directions
)

partial_high <- merge(
  support_partial_high[, c(
    "deg", "seg", "high_fraction"
  )],
  coverage_partial_high[, c(
    "deg", "seg", "coverage_fraction"
  )],
  by = c("deg", "seg")
)

partial_high$observed_support <- ifelse(
  partial_high$coverage_fraction > 0,
  partial_high$high_fraction /
    partial_high$coverage_fraction,
  NA_real_
)

selected <- partial_high[
  partial_high$deg %in% c(90, 270),
]

cat("\nE06 partial coverage with high exposure:\n")

print(
  selected[
    order(selected$deg, selected$seg),
  ],
  row.names = FALSE,
  digits = 5
)

western_first <- partial_high[
  partial_high$deg == 270 &
    partial_high$seg == "seg1",
]

stopifnot(
  nrow(western_first) == 1,
  abs(western_first$coverage_fraction - 0.5) < 0.02,
  abs(western_first$high_fraction - 0.5) < 0.02,
  abs(western_first$observed_support - 1) < 0.02
)

cat("\nE06 partial-high integration: PASSED\n")
