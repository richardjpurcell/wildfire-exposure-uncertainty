# D11.3 — Directional sensitivity to unresolved fuel classification
#
# Uses D10 reference geometry and geographic conventions.
# Highlights classifications changed by the unresolved
# 2026 FBP code 13 assignment.
#
# Viable / nonviable classifications are experimental.
# They do not indicate safe routes or predicted fire spread.

library(terra)
library(sf)
library(fireexposuR)
library(maptiles)

cat("\n=== D11.3: CLASSIFICATION SENSITIVITY MAP ===\n")

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
  "d11_directional_fuel_representation.csv"
)

output_path <- paste0(
  "outputs/figures/",
  "d11_classification_sensitivity.png"
)

stopifnot(
  file.exists(exposure_path),
  file.exists(points_path),
  file.exists(results_path)
)

exposure <- rast(exposure_path)

locations <- st_read(
  points_path,
  quiet = TRUE
)

selected <- locations[
  locations$location == "Westwood Hills",
]

stopifnot(nrow(selected) == 1)

point <- vect(selected)
xy <- crds(point)[1, ]

stopifnot(same.crs(exposure, point))

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

lines <- merge(
  lines,
  results[, c(
    "deg",
    "seg",
    "viable_baseline",
    "viable_package_upper",
    "transition"
  )],
  by = c("deg", "seg"),
  suffixes = c(".geometry", ".verified"),
  sort = FALSE
)

stopifnot(nrow(lines) == 108)

stopifnot(
  !anyDuplicated(lines[, c("deg", "seg")]),
  all(lines$viable == lines$viable_baseline),
  sum(lines$viable_baseline == 1) == 42,
  sum(lines$viable_package_upper == 1) == 58,
  sum(lines$transition == "newly_viable") == 16,
  sum(lines$transition == "stable_viable") == 42,
  sum(lines$transition == "stable_nonviable") == 50,
  !any(lines$transition == "no_longer_viable")
)

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

cache_dir <- "data/cache/d10_basemaps"

dir.create(
  cache_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

dir.create(
  dirname(output_path),
  recursive = TRUE,
  showWarnings = FALSE
)

cat("\nRetrieving OpenStreetMap basemap...\n")

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

# Lighten the basemap a bit more so the directional lines dominate.
light_grey <- 0.75 * grey + 0.25 * 255
neutral_tiles <- c(light_grey, light_grey, light_grey)

# Distance rings at the effective segment boundaries seen in D10.8.
ring_distances <- c(2038, 4076, 6114)

rings <- lapply(ring_distances, function(d) {
  st_boundary(st_buffer(selected, dist = d))
})

rings_sf <- do.call(rbind, rings)
rings_sf$label <- c("~2 km", "~4 km", "~6 km")

# Highlight classification dependence, not presumed safety.
line_colours <- ifelse(
  lines$transition == "newly_viable",
  "#D18A24",
  "#92979B"
)

line_widths <- ifelse(
  lines$transition == "newly_viable",
  3.8,
  1.8
)

png(
  filename = output_path,
  width = 2000,
  height = 2000,
  res = 200
)

tryCatch({

  par(mar = c(3.2, 0.5, 2.2, 0.5))

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

  plot(
    vect(lines),
    add = TRUE,
    col = line_colours,
    lwd = line_widths
  )

  # Segment-boundary separators.
  symbols(
    x = rep(xy[1], 2),
    y = rep(xy[2], 2),
    circles = c(2038, 4076),
    inches = FALSE,
    add = TRUE,
    bg = NA,
    fg = "white",
    lwd = 3.0
  )

  # Redraw the distance rings over the separators.
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
    cex = 1.8,
    lwd = 1.2
  )

  # Ring labels on the east side of the map.
  text(
    x = xy[1] + ring_distances,
    y = rep(xy[2] + 180, length(ring_distances)),
    labels = c("~2 km", "~4 km", "~6 km"),
    cex = 0.72,
    col = "grey20",
    pos = 4
  )

  title(
    main = "Westwood Hills | Directional classification sensitivity",
    cex.main = 1.05,
    line = 0.7
  )


  # Explicit legend keys to avoid missing entries.
  legend(
    x = xy[1] + 3650,
    y = xy[2] + 6100,
    legend = c("Changed to viable (16)", "Unchanged (92)"),
    col = c("#D18A24", "#92979B"),
    lty = c(1, 1),
    lwd = c(4, 2),
    bg = "white",
    bty = "o",
    cex = 0.85,
    xjust = 0,
    yjust = 1
  )

  legend(
    x = xy[1] - 6200,
    y = xy[2] - 5800,
    legend = "Westwood Hills",
    pch = 21,
    pt.bg = "deepskyblue",
    col = "black",
    bg = "white",
    bty = "o",
    cex = 0.80,
    xjust = 0,
    yjust = 0
  )

  mtext(
    "FBP code 13: 0 to 1 | exposure 0.60 | viability 0.80",
    side = 1,
    line = 0.8,
    cex = 0.72
  )

  mtext(
    "Map data: OpenStreetMap contributors",
    side = 1,
    line = 1.8,
    cex = 0.60
  )

}, finally = {
  dev.off()
})

stopifnot(
  file.exists(output_path),
  file.info(output_path)$size > 10000
)

cat("\nSegments:", nrow(lines), "\n")
cat("Stable:", sum(lines$transition != "newly_viable"), "\n")
cat("Changed:", sum(lines$transition == "newly_viable"), "\n")
cat("Output:", output_path, "\n")

cat("\nD11.3 rendering: PASSED\n")
