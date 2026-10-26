library(terra)

input_dir <- "data/processed/provincial-evidence"
output_dir <- "outputs/figures"

dir.create(
  output_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

layers <- c(
  named_species = "Named species composition",
  unclassified_species = "Explicitly unclassified species",
  no_first_story_description = "No first-story species description"
)

rasters <- lapply(names(layers), function(name) {
  path <- file.path(
    input_dir,
    paste0(name, "_100m.tif")
  )

  stopifnot(file.exists(path))

  rast(path)
})

names(rasters) <- names(layers)

reference <- rasters[[1]]

for (r in rasters) {
  stopifnot(
    compareGeom(reference, r, stopOnError = FALSE)
  )
}

output <- file.path(
  output_dir,
  "d03_provincial_evidence_coverage.png"
)

png(
  filename = output,
  width = 2400,
  height = 1000,
  res = 200
)

par(
  mfrow = c(1, 3),
  mar = c(3.5, 3.5, 3.5, 1.5),
  oma = c(2, 1, 2, 1)
)

palette <- colorRampPalette(
  c("#FFFFFF", "#DCE6E3", "#7DABA0", "#24594C")
)(100)

for (name in names(layers)) {

  r <- rasters[[name]]

  plot(
    r,
    col = palette,
    range = c(0, 1),
    main = layers[[name]],
    axes = TRUE,
    plg = list(
      title = "Coverage",
      shrink = 0.65
    ),
    xlab = "Easting (EPSG:3978)",
    ylab = "Northing (EPSG:3978)"
  )
}

mtext(
  "Nova Scotia provincial inventory on the 2026 FBP 100 m grid",
  outer = TRUE,
  side = 3,
  line = 0.3,
  cex = 1.2,
  font = 2
)

mtext(
  "Fractional forest-inventory coverage; not a measure of observation accuracy",
  outer = TRUE,
  side = 1,
  line = 0.3,
  cex = 0.9
)

dev.off()

cat("\n=== D03 evidence visualization ===\n")
cat("Saved:", output, "\n")
cat("Panels:", length(rasters), "\n")
cat("Coverage range: 0 to 1\n")
cat("D03 figure generation: COMPLETE\n")
