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
# D04.6: Map PHOTOYR within qualifying Non-fuel cells
# ============================================================

output <- "outputs/figures/d04_nonfuel_photo_year_map.png"

dir.create(
  dirname(output),
  recursive = TRUE,
  showWarnings = FALSE
)

year <- as.character(pieces$PHOTOYR)

groups <- ifelse(
  year == "1992",
  "1992",
  ifelse(year == "2003", "2003", "Other")
)

groups[is.na(groups)] <- "Other"

colours <- c(
  "1992" = "#4477AA",
  "2003" = "#CC8855",
  "Other" = "#888888"
)

png(
  filename = output,
  width = 2400,
  height = 2200,
  res = 200,
  bg = "white"
)

# Separate plotting regions for map and legend.
layout(
  matrix(c(1, 2), ncol = 1),
  heights = c(8, 2)
)

# Geographic map.
par(mar = c(4, 5, 3, 2))

plot(
  cells,
  col = "#F0F0F0",
  border = NA,
  main = "Provincial photograph years within federal Non-fuel cells",
  axes = TRUE
)

for (group in names(colours)) {
  selected <- which(groups == group)

  if (length(selected) > 0) {
    plot(
      pieces[selected, ],
      col = colours[group],
      border = NA,
      add = TRUE
    )
  }
}

plot(
  cells,
  col = NA,
  border = "#44444455",
  lwd = 0.3,
  add = TRUE
)

# Independent lower panel for legend and explanatory text.
par(mar = c(0, 2, 0, 2))

plot.new()
plot.window(xlim = c(0, 1), ylim = c(0, 1))

legend(
  "center",
  legend = c(
    "1992 imagery",
    "2003 imagery",
    "Other photograph years",
    "No provincial forest"
  ),
  fill = c(
    colours["1992"],
    colours["2003"],
    colours["Other"],
    "#F0F0F0"
  ),
  horiz = TRUE,
  bty = "n",
  cex = 0.8
)

text(
  0.5,
  0.12,
  "Federal FBP 2026 code 101; provincial LNDCLASS 99; at least 90% forest coverage",
  cex = 0.75,
  col = "#555555"
)

dev.off()

cat("\n=== D04.6 photograph-year map ===\n")

cat("Saved:", output, "\n")

cat("\n=== Mapped area by photograph-year group (ha) ===\n")

for (group in names(colours)) {
  cat(
    group, ":",
    round(sum(piece_area[groups == group]), 3),
    "\n"
  )
}

stopifnot(
  file.exists(output),
  abs(sum(piece_area) - 813.3697) < 0.01
)

cat("\nD04.6 map generation: PASSED\n")

