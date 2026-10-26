library(terra)

fbp <- rast(
  "data/processed/study-window/fbp_2026_candidate_100m.tif"
)

evidence_dir <- "data/processed/provincial-evidence"

read_evidence <- function(name) {
  path <- file.path(
    evidence_dir,
    paste0(name, "_100m.tif")
  )
  stopifnot(file.exists(path))
  r <- rast(path)
  stopifnot(compareGeom(fbp, r, stopOnError = FALSE))
  values(r, mat = FALSE)
}

named <- read_evidence("named_species")
unclassified <- read_evidence("unclassified_species")
no_description <- read_evidence("no_first_story_description")
clearcut <- read_evidence("clearcut_no_description")

codes <- values(fbp, mat = FALSE)

families <- c(
  "1" = "Conifer",
  "2" = "Conifer",
  "3" = "Conifer",
  "4" = "Conifer",
  "625" = "Mixedwood",
  "650" = "Mixedwood",
  "675" = "Mixedwood",
  "11" = "Deciduous",
  "31" = "Grass",
  "101" = "Non-fuel",
  "102" = "Water",
  "13" = "Vegetated, no FBP match"
)

family <- unname(families[as.character(codes)])

stopifnot(
  !anyNA(family),
  length(family) == ncell(fbp)
)

cell_area <- values(
  cellSize(fbp, unit = "ha", transform = TRUE),
  mat = FALSE
)

forest_fraction <- named + unclassified + no_description

tolerance <- 1e-6

stopifnot(
  all(is.finite(cell_area)),
  all(is.finite(forest_fraction)),
  all(forest_fraction >= -tolerance),
  all(forest_fraction <= 1 + tolerance),
  all(clearcut <= no_description + tolerance)
)

family_order <- c(
  "Conifer",
  "Mixedwood",
  "Deciduous",
  "Grass",
  "Non-fuel",
  "Water",
  "Vegetated, no FBP match"
)

results <- lapply(family_order, function(label) {
  selected <- family == label

  federal_area <- sum(cell_area[selected])

  named_area <- sum(named[selected] * cell_area[selected])
  unclassified_area <- sum(
    unclassified[selected] * cell_area[selected]
  )
  no_description_area <- sum(
    no_description[selected] * cell_area[selected]
  )
  clearcut_area <- sum(clearcut[selected] * cell_area[selected])

  provincial_forest_area <- (
    named_area + unclassified_area + no_description_area
  )

  percentage <- function(part, whole) {
    if (whole <= 0) return(NA_real_)
    100 * part / whole
  }

  data.frame(
    fbp_family = label,
    federal_cells = sum(selected),
    federal_area_ha = federal_area,
    provincial_forest_ha = provincial_forest_area,
    provincial_forest_pct_of_federal = percentage(
      provincial_forest_area, federal_area
    ),
    named_ha = named_area,
    named_pct_of_provincial_forest = percentage(
      named_area, provincial_forest_area
    ),
    unclassified_ha = unclassified_area,
    unclassified_pct_of_provincial_forest = percentage(
      unclassified_area, provincial_forest_area
    ),
    no_description_ha = no_description_area,
    no_description_pct_of_provincial_forest = percentage(
      no_description_area, provincial_forest_area
    ),
    clearcut_subset_ha = clearcut_area
  )
})

result <- do.call(rbind, results)

cat("\n=== D04: Federal–provincial area cross-tabulation ===\n")

display <- result
numeric_cols <- vapply(display, is.numeric, logical(1))
display[numeric_cols] <- lapply(
  display[numeric_cols],
  function(x) round(x, 2)
)

print(display, row.names = FALSE, width = 160)

cat("\n=== Validation ===\n")

cat(
  "Federal cells accounted for:",
  sum(result$federal_cells),
  "\n"
)

cat(
  "Total provincial forest area (ha):",
  round(sum(result$provincial_forest_ha), 3),
  "\n"
)

cat(
  "Total named species area (ha):",
  round(sum(result$named_ha), 3),
  "\n"
)

cat(
  "Total unclassified species area (ha):",
  round(sum(result$unclassified_ha), 3),
  "\n"
)

cat(
  "Total no-description area (ha):",
  round(sum(result$no_description_ha), 3),
  "\n"
)

cat(
  "Total clear-cut subset area (ha):",
  round(sum(result$clearcut_subset_ha), 3),
  "\n"
)

stopifnot(
  sum(result$federal_cells) == 40000,
  abs(sum(result$provincial_forest_ha) - 24254.77) < 0.1,
  abs(sum(result$named_ha) - 21670.81) < 0.1,
  abs(sum(result$unclassified_ha) - 1071.93) < 0.1,
  abs(sum(result$no_description_ha) - 1512.03) < 0.1
)

output <- "outputs/d04_fbp_provincial_evidence_cross_tab.csv"

write.csv(
  result,
  file = output,
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)

cat("\nSaved:", output, "\n")
cat("D04 cross-tabulation: PASSED\n")
