# D09 — Maintained entry point for selected figures
#
# Coordinates three verified renderers that produce:
# 1A satellite exposure
# 1B cartographic exposure
# 2A C-2/C-4 assumption sensitivity
# 2B unresolved-input sensitivity
#
# Run with --dry-run to verify inputs without rendering.
# Run without arguments to regenerate the four PNGs.

cat("\n=== D09: Selected figure rendering workflow ===\n")

args <- commandArgs(trailingOnly = TRUE)

stopifnot(
  length(args) <= 1,
  length(args) == 0 || identical(args, "--dry-run")
)

dry_run <- identical(args, "--dry-run")

renderers <- c(
  "scripts/d09_render_reference_exposure_pair_grayscale_45.R",
  "scripts/d09_render_conifer_stability_map_v2.R",
  "scripts/d09_render_unresolved_sensitivity_map_v2.R"
)

inputs <- c(
  "data/processed/visualization/d09_reference_exposure_2026_500m.tif",
  "data/processed/visualization/d09_unresolved_sensitivity_2026_500m.tif",
  "data/processed/visualization/d09_scenario_A_delta_lower_500m.tif",
  "data/processed/visualization/d09_scenario_A_delta_upper_500m.tif",
  "data/processed/visualization/d09_scenario_B_delta_lower_500m.tif",
  "data/processed/visualization/d09_scenario_B_delta_upper_500m.tif",
  "data/processed/study-window/reference_points.gpkg"
)

outputs <- c(
  "outputs/figures/d09_satellite_exposure_grayscale_45.png",
  "outputs/figures/d09_cartographic_exposure_grayscale_45.png",
  "outputs/figures/d09_conifer_stability_map_v2.png",
  "outputs/figures/d09_unresolved_sensitivity_map_v2.png"
)

required <- c(renderers, inputs)

missing <- required[!file.exists(required)]

if (length(missing) > 0) {
  stop(
    "Missing required inputs:\n",
    paste(missing, collapse = "\n")
  )
}

cat("\nRequired scripts and inputs: PASSED\n")

if (dry_run) {
  cat("\nDry run: renderers not executed.\n")

  for (path in outputs) {
    cat(
      if (file.exists(path)) "PRESENT:" else "MISSING:",
      path, "\n"
    )
  }

  cat("\nD09 dry-run verification: PASSED\n")
  quit(save = "no", status = 0)
}

# Preserve the working directory and execute the
# selected, previously verified renderer implementations.

rscript <- file.path(R.home("bin"), "Rscript")

for (script in renderers) {
  cat("\nRunning:", script, "\n")

  result <- system2(
    rscript,
    args = script,
    stdout = "",
    stderr = ""
  )

  if (result != 0) {
    stop("Renderer failed: ", script)
  }
}

for (path in outputs) {
  stopifnot(
    file.exists(path),
    file.info(path)$size > 10000
  )

  cat("VERIFIED:", path, "\n")
}

cat("\nD09 selected figure rendering: PASSED\n")
