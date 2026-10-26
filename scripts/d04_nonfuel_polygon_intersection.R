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
