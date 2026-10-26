library(terra)

fbp <- rast(
  "data/processed/study-window/fbp_2026_candidate_100m.tif"
)

evidence_dir <- "data/processed/provincial-evidence"

read_fraction <- function(name) {
  r <- rast(file.path(
    evidence_dir,
    paste0(name, "_100m.tif")
  ))

  stopifnot(compareGeom(fbp, r, stopOnError = FALSE))
  values(r, mat = FALSE)
}

named <- read_fraction("named_species")
unclassified <- read_fraction("unclassified_species")
no_description <- read_fraction("no_first_story_description")

forest_fraction <- named + unclassified + no_description
codes <- values(fbp, mat = FALSE)

qualifying <- which(
  codes == 101 &
  forest_fraction >= 0.90
)

stopifnot(length(qualifying) == 850)

# Construct one polygon per qualifying federal raster cell.
selected <- fbp
values(selected) <- rep(NA_real_, ncell(fbp))
selected[qualifying] <- qualifying

names(selected) <- "cell_id"

cells <- as.polygons(
  selected,
  dissolve = FALSE,
  na.rm = TRUE
)

stopifnot(nrow(cells) == 850)

cat("\n=== Qualifying federal cell polygons ===\n")
cat("Cell polygons:", nrow(cells), "\n")
cat("CRS:", crs(cells, describe = TRUE)$name, "\n")

# Read the same provincial forest source used by D03.
forest <- vect(
  "data/raw/ns-forest-inventory/halifax-west/forest.shp"
)

boundary <- vect(
  "data/processed/study-window/study_boundary.gpkg"
)

local <- crop(
  forest,
  project(boundary, crs(forest))
)

local <- local[
  which(!is.na(local$LNDCLASS) & local$LNDCLASS == 99),
]

cat("\n=== Provincial source selection ===\n")
cat("Forest polygons before intersection:", nrow(local), "\n")

# Align vector geometry to the federal raster CRS.
local <- project(local, crs(fbp))

# Preserve the source attributes through the intersection.
pieces <- intersect(local, cells)

stopifnot(
  nrow(pieces) > 0,
  "cell_id" %in% names(pieces)
)

# Use geographically corrected hectares, as in D03/D04.
piece_area <- expanse(
  pieces,
  unit = "ha",
  transform = TRUE
)

stopifnot(
  all(is.finite(piece_area)),
  all(piece_area >= 0)
)

cat("\n=== Vector intersection ===\n")
cat("Intersection pieces:", nrow(pieces), "\n")
cat(
  "Federal cells with provincial intersections:",
  length(unique(pieces$cell_id)),
  "\n"
)

vector_area <- sum(piece_area)

raster_cell_area <- values(
  cellSize(fbp, unit = "ha", transform = TRUE),
  mat = FALSE
)

raster_area <- sum(
  forest_fraction[qualifying] *
  raster_cell_area[qualifying]
)

cat("\n=== Area comparison ===\n")

cat(
  "D04.2 raster-derived forest area (ha):",
  round(raster_area, 4),
  "\n"
)

cat(
  "D04.3 vector intersection area (ha):",
  round(vector_area, 4),
  "\n"
)

cat(
  "Difference, vector minus raster (ha):",
  round(vector_area - raster_area, 4),
  "\n"
)

cat(
  "Relative difference (%):",
  round(
    100 * (vector_area - raster_area) / raster_area,
    4
  ),
  "\n"
)

cat("\n=== Attribute preservation ===\n")

required <- c(
  "SPECIES",
  "PHOTOYR",
  "FORNON",
  "LNDCLASS",
  "cell_id"
)

print(required %in% names(pieces))

stopifnot(all(required %in% names(pieces)))

cat("\nD04.3 intersection diagnostic: COMPLETE\n")

# ============================================================
# D04.4: Area-weighted provincial attribute diagnostics
# ============================================================

pieces$area_ha <- piece_area

species <- trimws(as.character(pieces$SPECIES))

pieces$evidence_status <- ifelse(
  is.na(species) | species == "",
  "No first-story description",
  ifelse(
    species == "UC10",
    "Explicitly unclassified (UC10)",
    "Named species"
  )
)

pieces$species_code <- ifelse(
  is.na(species) | species == "",
  "(missing)",
  species
)

area_summary <- function(group, area) {
  result <- aggregate(
    area,
    by = list(category = as.character(group)),
    FUN = sum
  )

  names(result)[2] <- "area_ha"

  result <- result[
    order(-result$area_ha),
  ]

  result$percent <- 100 * result$area_ha / sum(area)

  rownames(result) <- NULL
  result
}

print_summary <- function(title, result, limit = nrow(result)) {
  cat("\n=== ", title, " ===\n", sep = "")

  display <- head(result, limit)
  display$area_ha <- round(display$area_ha, 3)
  display$percent <- round(display$percent, 2)

  print(display, row.names = FALSE)
}

# 1. Species evidence status
status_summary <- area_summary(
  pieces$evidence_status,
  pieces$area_ha
)

print_summary(
  "Species evidence status (area-weighted)",
  status_summary
)

# 2. Photograph year
photo_year <- as.character(pieces$PHOTOYR)
photo_year[is.na(photo_year) | trimws(photo_year) == ""] <- "(missing)"

photo_summary <- area_summary(
  photo_year,
  pieces$area_ha
)

print_summary(
  "PHOTOYR distribution (area-weighted)",
  photo_summary
)

# 3. FORNON classification
fornon <- as.character(pieces$FORNON)
fornon[is.na(fornon) | trimws(fornon) == ""] <- "(missing)"

fornon_summary <- area_summary(
  fornon,
  pieces$area_ha
)

print_summary(
  "FORNON distribution (area-weighted)",
  fornon_summary
)

# 4. Exact species descriptions
species_summary <- area_summary(
  pieces$species_code,
  pieces$area_ha
)

print_summary(
  "Top 20 exact SPECIES descriptions",
  species_summary,
  limit = 20
)

# 5. Clear-cut association with missing descriptions
clearcut_missing <- (
  pieces$evidence_status == "No first-story description" &
  !is.na(pieces$FORNON) &
  pieces$FORNON == 60
)

cat("\n=== Clear-cut and missing description association ===\n")

cat(
  "Clear-cut with no species description (ha):",
  round(sum(pieces$area_ha[clearcut_missing]), 3),
  "\n"
)

cat(
  "Total missing-description area (ha):",
  round(sum(
    pieces$area_ha[
      pieces$evidence_status == "No first-story description"
    ]
  ), 3),
  "\n"
)

# 6. Validate area conservation across summaries
total <- sum(pieces$area_ha)

stopifnot(
  abs(sum(status_summary$area_ha) - total) < 1e-6,
  abs(sum(photo_summary$area_ha) - total) < 1e-6,
  abs(sum(fornon_summary$area_ha) - total) < 1e-6,
  abs(sum(species_summary$area_ha) - total) < 1e-6
)

cat("\n=== D04.4 validation ===\n")
cat("Total intersection area (ha):", round(total, 4), "\n")
cat("All attribute summaries conserve area: PASSED\n")


# ============================================================
# D04.5: PHOTOYR relationships with evidence and FORNON
# ============================================================

cat("\n=== D04.5 PHOTOYR analysis ===\n")

year <- as.character(pieces$PHOTOYR)
year[is.na(year) | trimws(year) == ""] <- "(missing)"

year_group <- ifelse(
  year %in% c("1992", "2003"),
  year,
  "Other / missing"
)

weighted_table <- function(row_group, column_group, area) {
  result <- xtabs(
    area ~ row_group + column_group,
    data = data.frame(
      row_group = row_group,
      column_group = column_group,
      area = area
    )
  )

  round(result, 3)
}

cat("\n=== PHOTOYR x species evidence status (ha) ===\n")

evidence_table <- weighted_table(
  year_group,
  pieces$evidence_status,
  pieces$area_ha
)

print(evidence_table)

cat("\n=== PHOTOYR x FORNON (ha) ===\n")

fornon_group <- ifelse(
  !is.na(pieces$FORNON) & pieces$FORNON == 60,
  "FORNON 60",
  ifelse(
    !is.na(pieces$FORNON) & pieces$FORNON == 0,
    "FORNON 0",
    "Other / missing"
  )
)

fornon_table <- weighted_table(
  year_group,
  fornon_group,
  pieces$area_ha
)

print(fornon_table)

cat("\n=== Photograph-year group totals ===\n")

print(round(rowSums(evidence_table), 3))

cat("\n=== Validation ===\n")

total <- sum(pieces$area_ha)

stopifnot(
  abs(sum(evidence_table) - total) < 0.01,
  abs(sum(fornon_table) - total) < 0.01
)

cat("Total intersection area (ha):", round(total, 4), "\n")
cat("D04.5 area conservation: PASSED\n")
