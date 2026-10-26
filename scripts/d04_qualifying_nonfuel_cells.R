library(terra)

fbp <- rast(
  "data/processed/study-window/fbp_2026_candidate_100m.tif"
)

evidence_dir <- "data/processed/provincial-evidence"

read_fraction <- function(name) {
  r <- rast(
    file.path(
      evidence_dir,
      paste0(name, "_100m.tif")
    )
  )

  stopifnot(compareGeom(fbp, r, stopOnError = FALSE))

  values(r, mat = FALSE)
}

named <- read_fraction("named_species")
unclassified <- read_fraction("unclassified_species")
no_description <- read_fraction("no_first_story_description")
clearcut <- read_fraction("clearcut_no_description")

forest_fraction <- named + unclassified + no_description

fbp_codes <- values(fbp, mat = FALSE)

cell_area <- values(
  cellSize(
    fbp,
    unit = "ha",
    transform = TRUE
  ),
  mat = FALSE
)

stopifnot(
  all(is.finite(forest_fraction)),
  all(is.finite(cell_area)),
  all(forest_fraction >= -1e-6),
  all(forest_fraction <= 1 + 1e-6),
  all(clearcut <= no_description + 1e-6)
)

qualifying <- which(
  fbp_codes == 101 &
  forest_fraction >= 0.90
)

cat("\n=== D04.2 qualifying Non-fuel cells ===\n")

cat("Qualifying cells:", length(qualifying), "\n")

area_by_category <- c(
  named_species = sum(named[qualifying] * cell_area[qualifying]),
  unclassified_species = sum(
    unclassified[qualifying] * cell_area[qualifying]
  ),
  no_first_story_description = sum(
    no_description[qualifying] * cell_area[qualifying]
  ),
  clearcut_subset = sum(
    clearcut[qualifying] * cell_area[qualifying]
  )
)

total_forest <- sum(
  forest_fraction[qualifying] * cell_area[qualifying]
)

cat(
  "Total federal cell area (ha):",
  round(sum(cell_area[qualifying]), 4),
  "\n"
)

cat(
  "Provincial forest area (ha):",
  round(total_forest, 4),
  "\n"
)

cat("\n=== Evidence composition (ha) ===\n")
print(round(area_by_category, 4))

cat("\n=== Validation ===\n")

stopifnot(
  length(qualifying) == 850,
  abs(total_forest - 813.73) < 0.1,
  abs(area_by_category["named_species"] - 722.53) < 0.1,
  abs(area_by_category["unclassified_species"] - 32.25) < 0.1,
  abs(area_by_category["no_first_story_description"] - 58.95) < 0.1,
  abs(area_by_category["clearcut_subset"] - 50.66) < 0.1
)

cat("D04.2 qualifying cell selection: PASSED\n")
