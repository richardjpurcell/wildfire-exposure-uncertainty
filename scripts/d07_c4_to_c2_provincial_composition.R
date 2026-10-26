# D07 — Provincial composition for 2024 C-4 -> 2026 C-2
#
# Uses exact polygon intersection and area-weighted
# first-story species components.
#
# Provincial inventory is evidence, not ground truth.
# Species contributions are interpreted within the
# inventory's recorded first-story composition.

library(terra)

cat("\n=== D07: Reproducible provincial composition ===\n")

r24 <- rast(
  "data/processed/study-window/fbp_2024_aligned_100m.tif"
)

r26 <- rast(
  "data/processed/study-window/fbp_2026_candidate_100m.tif"
)

stopifnot(
  compareGeom(r24, r26, stopOnError = FALSE),
  ncell(r24) == 40000
)

selection <- (
  values(r24, mat = FALSE) == 4 &
  values(r26, mat = FALSE) == 2
)

stopifnot(
  !anyNA(selection),
  sum(selection) == 3568
)

target <- as.polygons(
  ifel(r24 == 4 & r26 == 2, 1, NA),
  dissolve = TRUE,
  na.rm = TRUE
)

target_area_ha <- sum(
  as.numeric(expanse(target, unit = "ha"))
)

forest <- vect(
  "data/raw/ns-forest-inventory/halifax-west/forest.shp"
)

forest <- forest[forest$LNDCLASS == 99, ]
forest <- project(forest, crs(target))

intersection <- intersect(
  crop(forest, ext(target)),
  target
)

stopifnot(nrow(intersection) > 0)

a <- values(intersection, dataframe = TRUE)

a$area_ha <- as.numeric(
  expanse(intersection, unit = "ha")
)

component_fields <- paste0("SP", 1:4, "P")
code_fields <- paste0("SP", 1:4)

component_totals <- rowSums(
  a[, component_fields, drop = FALSE],
  na.rm = TRUE
)

stopifnot(
  all(component_totals %in% c(0, 10))
)

described <- component_totals == 10

forest_area_ha <- sum(a$area_ha)
described_area_ha <- sum(a$area_ha[described])
undesc_area_ha <- sum(a$area_ha[!described])

summary <- data.frame(
  metric = c(
    "selected_cells",
    "target_area_ha",
    "provincial_forest_area_ha",
    "described_forest_area_ha",
    "undescribed_forest_area_ha",
    "provincial_forest_percent_of_target",
    "described_percent_of_provincial_forest"
  ),
  value = c(
    sum(selection),
    target_area_ha,
    forest_area_ha,
    described_area_ha,
    undesc_area_ha,
    100 * forest_area_ha / target_area_ha,
    100 * described_area_ha / forest_area_ha
  )
)

cat("\n=== Area summary ===\n")
print(summary, row.names = FALSE)

# Area-weight each reported component.
contributions <- list()

for (i in seq_along(code_fields)) {

  code <- trimws(a[[code_fields[i]]])
  proportion <- a[[component_fields[i]]]

  valid <- described &
    !is.na(code) &
    nzchar(code) &
    !is.na(proportion) &
    proportion > 0

  contributions[[i]] <- data.frame(
    species_code = code[valid],
    weighted_ha = (
      a$area_ha[valid] * proportion[valid] / 10
    )
  )
}

species <- do.call(rbind, contributions)

composition <- aggregate(
  weighted_ha ~ species_code,
  data = species,
  FUN = sum
)

composition <- composition[
  order(-composition$weighted_ha),
]

composition$percent_described <- (
  100 * composition$weighted_ha / described_area_ha
)

composition$percent_all_forest <- (
  100 * composition$weighted_ha / forest_area_ha
)

rownames(composition) <- NULL

cat("\n=== Leading species codes ===\n")
print(head(composition, 12), row.names = FALSE)

# The field PHOTOYR identifies the source inventory's
# recorded year of forest-attribute collection.
years <- aggregate(
  a$area_ha[described],
  by = list(PHOTOYR = a$PHOTOYR[described]),
  FUN = sum
)

names(years)[2] <- "described_area_ha"

years <- years[
  order(-years$described_area_ha),
]

years$percent_described <- (
  100 * years$described_area_ha / described_area_ha
)

rownames(years) <- NULL

cat("\n=== Evidence years ===\n")
print(years, row.names = FALSE)

cat("\n=== Validation ===\n")

stopifnot(
  abs(target_area_ha - 3436.711) < 0.1,
  abs(forest_area_ha - 3040.746) < 0.1,
  abs(described_area_ha - 2834.208) < 0.1,
  abs(undesc_area_ha - 206.5378) < 0.1,
  abs(sum(composition$weighted_ha) -
      described_area_ha) < 0.01,
  abs(sum(years$described_area_ha) -
      described_area_ha) < 0.01
)

expected_top <- c("RS", "BF", "BS", "RM", "XS")

stopifnot(
  identical(
    head(composition$species_code, 5),
    expected_top
  )
)

# Preserve full precision in the output files.
dir.create(
  "outputs/tables",
  recursive = TRUE,
  showWarnings = FALSE
)

write.csv(
  summary,
  "outputs/tables/d07_c4_to_c2_area_summary.csv",
  row.names = FALSE
)

write.csv(
  composition,
  "outputs/tables/d07_c4_to_c2_species_composition.csv",
  row.names = FALSE
)

write.csv(
  years,
  "outputs/tables/d07_c4_to_c2_evidence_years.csv",
  row.names = FALSE
)

cat("\nD07 reproducibility: PASSED\n")
