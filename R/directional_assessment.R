# Integrated directional exposure assessment.
#
# Combines:
#   1. High-exposure support over total segment length
#   2. Evidence coverage
#   3. High-exposure support among observed evidence
#   4. Reconstructed package-compatible viability
#
# Requires directional_support.R and directional_coverage.R.

directional_assessment <- function(
    exposure,
    transects,
    thresh_exp = 0.60,
    thresh_viable = 0.80) {

  support <- directional_support(
    exposure = exposure,
    transects = transects,
    thresh_exp = thresh_exp,
    thresh_viable = thresh_viable
  )

  coverage <- directional_coverage(
    exposure = exposure,
    transects = transects
  )

  result <- merge(
    support,
    coverage[, c(
      "deg",
      "seg",
      "observed_length_m",
      "coverage_fraction"
    )],
    by = c("deg", "seg")
  )

  # Undefined when the segment has no observed evidence.
  # Suppress ratios formed from negligible intersection lengths.
  # This is a numerical tolerance, not an evidence-sufficiency rule.
  coverage_tolerance <- 1e-8

  result$observed_support <- ifelse(
    result$coverage_fraction > coverage_tolerance,
    result$high_length_m / result$observed_length_m,
    NA_real_
  )

  # Useful distinction for downstream reporting.
  result$evidence_status <- ifelse(
    result$coverage_fraction <= coverage_tolerance,
    "missing",
    ifelse(
      result$coverage_fraction >= 1 - 1e-8,
      "complete",
      "partial"
    )
  )

  result <- result[
    order(result$deg, result$seg),
  ]

  rownames(result) <- NULL

  result
}
