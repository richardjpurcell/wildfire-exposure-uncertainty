# D11.4 — Four-scenario directional stability visualization
#
# Reuses the D10/D11 directional geometry, Westwood Hills
# reference point, geographic extent and basemap conventions.
#
# Panel A: classification stability across four scenarios.
# Panel B: robust differences between FBP editions.
#
# These classifications do not represent safe routes or
# observed environmental changes.

suppressPackageStartupMessages({
  library(terra)
  library(sf)
  library(fireexposuR)
  library(maptiles)
})

cat("\n=== D11.4: TWO-PANEL DIRECTIONAL STABILITY MAP ===\n")

exposure_path <- paste0(
  "data/processed/visualization/",
  "d09_reference_exposure_2026_500m.tif"
)

points_path <- paste0(
  "data/processed/study-window/",
  "reference_points.gpkg"
)

results_path <- paste0(
  "outputs/tables/",
  "d11_four_scenario_directional_stability.csv"
)

output_path <- paste0(
  "outputs/figures/",
  "d11_four_scenario_directional_stability.png"
)

stopifnot(
  file.exists(exposure_path),
  file.exists(points_path),
  file.exists(results_path),
  !file.exists(output_path)
)

exposure <- rast(exposure_path)

locations <- st_read(points_path, quiet = TRUE)

selected <- locations[
  locations$location == "Westwood Hills",
]

stopifnot(nrow(selected) == 1)

point <- vect(selected)
xy <- crds(point)[1, ]

stopifnot(same.crs(exposure, point))

cat("\n=== RECONSTRUCTING REFERENCE GEOMETRY ===\n")

directions <- fire_exp_dir(
  exposure = exposure,
  value = point,
  t_lengths = c(2000, 2000, 2000),
  interval = 10,
  thresh_exp = 0.60,
  thresh_viable = 0.80
)

lines <- st_as_sf(directions)

results <- read.csv(
  results_path,
  stringsAsFactors = FALSE
)

stopifnot(
  nrow(lines) == 108,
  nrow(results) == 108,
  !anyDuplicated(
    paste(lines$deg, lines$seg)
  ),
  !anyDuplicated(
    paste(results$deg, results$seg)
  )
)

lines <- merge(
  lines,
  results,
  by = c("deg", "seg"),
  sort = FALSE
)

stopifnot(
  nrow(lines) == 108,
  !anyNA(lines$stability),
  !anyNA(lines$edition_difference),
  all(lines$viable == lines$y26L),
  sum(lines$y24L) == 53,
  sum(lines$y24U) == 82,
  sum(lines$y26L) == 42,
  sum(lines$y26U) == 58,
  sum(lines$stability == "always_viable") == 38,
  sum(lines$stability == "always_nonviable") == 22,
  sum(lines$stability == "variable") == 48,
  sum(
    lines$edition_difference ==
      "2024_viable_2026_nonviable"
  ) == 9,
  sum(
    lines$edition_difference ==
      "2024_nonviable_2026_viable"
  ) == 2
)

cat("108 verified directional geometries: PASSED\n")
cat("Stability categories: 38 / 22 / 48\n")
cat("Robust edition differences: 9 / 2\n")

view <- ext(
  xy[1] - 7000,
  xy[1] + 7000,
  xy[2] - 7000,
  xy[2] + 7000
)

bbox <- st_bbox(lines)

stopifnot(
  bbox["xmin"] >= xmin(view),
  bbox["xmax"] <= xmax(view),
  bbox["ymin"] >= ymin(view),
  bbox["ymax"] <= ymax(view)
)

window_sf <- st_as_sf(
  as.polygons(view, crs = crs(exposure))
)

cat("\n=== BASEMAP ===\n")

cache_dir <- "data/cache/d10_basemaps"

stopifnot(dir.exists(cache_dir))

tiles <- maptiles::get_tiles(
  x = window_sf,
  provider = "OpenStreetMap",
  zoom = 12,
  crop = TRUE,
  project = TRUE,
  cachedir = cache_dir
)

stopifnot(
  inherits(tiles, "SpatRaster"),
  nlyr(tiles) >= 3,
  same.crs(tiles, exposure)
)

grey <- (
  0.299 * tiles[[1]] +
  0.587 * tiles[[2]] +
  0.114 * tiles[[3]]
)

light_grey <- 0.75 * grey + 0.25 * 255

neutral_tiles <- c(
  light_grey, light_grey, light_grey
)

ring_distances <- c(2038, 4076, 6114)

rings <- lapply(ring_distances, function(d) {
  st_boundary(st_buffer(selected, dist = d))
})

rings_sf <- do.call(rbind, rings)

# Draw one classification group at a time.
draw_group <- function(field, value, colour, width) {
  subset <- lines[
    lines[[field]] == value,
  ]

  if (nrow(subset) > 0) {
    plot(
      vect(subset),
      add = TRUE,
      col = colour,
      lwd = width
    )
  }
}

draw_background <- function() {
  plotRGB(
    neutral_tiles,
    r = 1,
    g = 2,
    b = 3,
    ext = view,
    axes = FALSE
  )

  plot(
    vect(rings_sf),
    add = TRUE,
    col = "grey35",
    lty = 2,
    lwd = 1.2
  )
}

draw_foreground <- function() {
  # Separate adjacent directional segments visually.
  symbols(
    x = rep(xy[1], 2),
    y = rep(xy[2], 2),
    circles = c(2038, 4076),
    inches = FALSE,
    add = TRUE,
    bg = NA,
    fg = "white",
    lwd = 2.5
  )

  plot(
    vect(rings_sf),
    add = TRUE,
    col = "grey35",
    lty = 2,
    lwd = 1.2
  )

  points(
    xy[1],
    xy[2],
    pch = 21,
    bg = "deepskyblue",
    col = "black",
    cex = 1.5,
    lwd = 1.2
  )

  text(
    x = xy[1] + ring_distances,
    y = rep(xy[2] + 180, 3),
    labels = c("~2 km", "~4 km", "~6 km"),
    cex = 0.60,
    col = "grey20",
    pos = 4
  )
}

draw_legend <- function(labels, colours, widths) {
  plot.new()
  legend(
    "center",
    legend = labels,
    col = colours,
    lty = 1,
    lwd = widths,
    cex = 1.65,
    bty = "n",
    x.intersp = 0.7,
    y.intersp = 1.1
  )
}

dir.create(
  dirname(output_path),
  recursive = TRUE,
  showWarnings = FALSE
)

cat("\n=== RENDERING ===\n")

png(
  filename = output_path,
  width = 3600,
  height = 1900,
  res = 200
)

tryCatch({

  layout(
    matrix(c(1, 2, 3, 4), nrow = 2, byrow = TRUE),
    heights = c(8, 2.2)
  )

  par(
    mar = c(3.2, 0.6, 2.6, 0.6),
    oma = c(0.4, 0, 0, 0)
  )

  # Panel A: stability across all four scenarios.
  draw_background()

  draw_group(
    "stability",
    "always_nonviable",
    "#92979B",
    2.0
  )

  draw_group(
    "stability",
    "always_viable",
    "#447C65",
    2.8
  )

  draw_group(
    "stability",
    "variable",
    "#D18A24",
    3.4
  )

  draw_foreground()

  title(
    main = "A | Classification stability",
    cex.main = 1.15,
    line = 0.8
  )



  mtext(
    "2024 and 2026 | lower and upper assignments",
    side = 1,
    line = 1.0,
    cex = 0.70
  )

  mtext(
    "Exposure 0.60 | viability 0.80",
    side = 1,
    line = 2.0,
    cex = 0.64
  )

  # Panel B: only differences robust to unresolved assignments.
  draw_background()

  draw_group(
    "edition_difference",
    "not_robustly_separated",
    "#B7BABC",
    1.4
  )

  draw_group(
    "edition_difference",
    "2024_viable_2026_nonviable",
    "#BD7654",
    4.3
  )

  draw_group(
    "edition_difference",
    "2024_nonviable_2026_viable",
    "#5184A3",
    4.3
  )

  draw_foreground()

  title(
    main = "B | Robust edition differences",
    cex.main = 1.15,
    line = 0.8
  )



  mtext(
    "Different in both unresolved-code assignments",
    side = 1,
    line = 1.0,
    cex = 0.70
  )

  mtext(
    "Map data: OpenStreetMap contributors",
    side = 1,
    line = 2.0,
    cex = 0.64
  )

  # Separate readable legend panels below the two maps.
  par(mar = c(0, 0, 0, 0))

  draw_legend(
    c(
      "Always viable (38)",
      "Always nonviable (22)",
      "Variable (48)"
    ),
    c("#447C65", "#92979B", "#D18A24"),
    c(3, 2, 4)
  )

  draw_legend(
    c(
      "2024 viable / 2026 nonviable (9)",
      "2024 nonviable / 2026 viable (2)",
      "Not robustly separated (97)"
    ),
    c("#BD7654", "#5184A3", "#B7BABC"),
    c(4, 4, 1.5)
  )

}, finally = {
  dev.off()
})

stopifnot(
  file.exists(output_path),
  file.info(output_path)$size > 10000
)

cat("Output:", output_path, "\n")
cat("Size:", file.info(output_path)$size, "bytes\n")

cat("\nD11.4 TWO-PANEL RENDERING: PASSED\n")
