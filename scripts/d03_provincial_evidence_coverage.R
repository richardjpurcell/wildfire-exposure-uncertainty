library(terra)

forest_path <- paste0(
  "data/raw/ns-forest-inventory/",
  "halifax-west/forest.shp"
)

boundary_path <- paste0(
  "data/processed/study-window/",
  "study_boundary.gpkg"
)

reference_path <- paste0(
  "data/processed/study-window/",
  "fbp_2026_candidate_100m.tif"
)

output_dir <- "data/processed/provincial-evidence"

dir.create(
  output_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

stopifnot(
  file.exists(forest_path),
  file.exists(boundary_path),
  file.exists(reference_path)
)

forest <- vect(forest_path)
boundary <- vect(boundary_path)
reference <- rast(reference_path)

local <- crop(
  forest,
  project(boundary, crs(forest))
)

local <- local[local$LNDCLASS == 99, ]

species <- trimws(local$SPECIES)

missing_species <- is.na(species) | species == ""

named <- !missing_species & species != "UC10"

unclassified <- !missing_species & species == "UC10"

no_description <- missing_species

clearcut <- no_description & local$FORNON == 60

categories <- list(
  named_species = named,
  unclassified_species = unclassified,
  no_first_story_description = no_description,
  clearcut_no_description = clearcut
)

cat("\n=== Provincial evidence-status coverage ===\n")

results <- list()

for (name in names(categories)) {

  selected <- local[which(categories[[name]]), ]

  selected <- project(
    selected,
    crs(reference)
  )

  coverage <- rasterize(
    selected,
    reference,
    cover = TRUE,
    background = 0
  )

  names(coverage) <- name

  values_local <- values(
    coverage,
    mat = FALSE
  )

  stopifnot(
    all(is.finite(values_local)),
    all(values_local >= -1e-8),
    all(values_local <= 1 + 1e-8)
  )

  output <- file.path(
    output_dir,
    paste0(name, "_100m.tif")
  )

  writeRaster(
    coverage,
    output,
    overwrite = TRUE
  )

  area_ha <- sum(
    values_local *
    values(
      cellSize(
        reference,
        unit = "ha",
        transform = TRUE
      ),
      mat = FALSE
    )
  )

  results[[name]] <- data.frame(
    category = name,
    polygons = nrow(selected),
    cells_with_coverage = sum(values_local > 1e-8),
    area_ha = round(area_ha, 2)
  )

  cat("\nCategory:", name, "\n")
  cat("Polygons:", nrow(selected), "\n")
  cat("Cells with coverage:", sum(values_local > 1e-8), "\n")
  cat("Area (ha):", round(area_ha, 2), "\n")
  cat("Saved:", output, "\n")
}

summary <- do.call(rbind, results)

cat("\n=== Coverage summary ===\n")
print(summary, row.names = FALSE)

cat("\nProvincial coverage generation: COMPLETE\n")
