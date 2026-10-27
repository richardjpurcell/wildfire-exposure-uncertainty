# D10.11 — Improved baseline directional map
#
# Adds distance rings so the three successive directional
# segments are readable in geographic space.
#
# Viable / nonviable classifications are experimental.
# They do not indicate safe routes or predicted fire spread.

library(terra)
library(sf)
library(fireexposuR)
library(maptiles)

cat("\n=== D10.11a: REFINED BASELINE DIRECTIONAL MAP ===\n")

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
  "d10_threshold_stability.csv"
)

output_path <- paste0(
  "outputs/figures/",
  "d10_threshold_stability_preliminary.png"
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
  results[, c("deg", "seg", "baseline_viable", "viable_fraction")],
  by = c("deg", "seg"),
  suffixes = c(".geometry", ".verified"),
  sort = FALSE
)

stopifnot(nrow(lines) == 108)

# The threshold-grid table must match the baseline geometry
# and classifications from fire_exp_dir().

stopifnot(
  all(lines$viable == lines$baseline_viable),
  sum(lines$viable == 1) == 42,
  sum(lines$viable == 0) == 66,
  all(is.finite(lines$viable_fraction)),
  all(lines$viable_fraction >= 0),
  all(lines$viable_fraction <= 1),
  sum(lines$viable_fraction == 0) == 21,
  sum(lines$viable_fraction == 1) == 8,
  sum(lines$viable_fraction > 0 &
      lines$viable_fraction < 1) == 79
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

# Five ordered classes for threshold-grid viable fraction.
# The scale is fixed between zero and one.

stability_breaks <- seq(0, 1, by = 0.2)

stability_palette <- c(
  "#C8C9CC",
  "#BEB4D2",
  "#9F8DBD",
  "#76649F",
  "#40366F"
)

stability_class <- cut(
  lines$viable_fraction,
  breaks = stability_breaks,
  include.lowest = TRUE,
  labels = FALSE
)

stopifnot(
  length(stability_class) == 108,
  !anyNA(stability_class)
)

line_colours <- stability_palette[stability_class]

png(
  filename = output_path,
  width = 2000,
  height = 2400,
  res = 200
)

tryCatch({

  layout(matrix(c(1, 2), ncol = 1), heights = c(8.5, 1.8))

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
    lwd = 2.6
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
    main = "Westwood Hills | Directional threshold sensitivity",
    cex.main = 1.05,
    line = 0.7
  )


  # Ordered legend for the 72-setting viability fraction.


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
    "Viable fraction across 72 experimental threshold combinations",
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


    # Larger categorical legend beneath the directional map.
    par(mar = c(0, 0, 0, 0))
    plot.new()
    legend(
      "center",
      legend = c(
        "0.0–0.2", "0.2–0.4", "0.4–0.6",
        "0.6–0.8", "0.8–1.0"
      ),
      col = stability_palette,
      lty = 1,
      lwd = 4,
      title = "Viable fraction",
      ncol = 2,
      cex = 1.35,
      x.intersp = 0.8,
      y.intersp = 1.2,
      bty = "n"
    )

}, finally = {
  dev.off()
})

stopifnot(
  file.exists(output_path),
  file.info(output_path)$size > 10000
)

cat("\nSegments:", nrow(lines), "\n")
cat("Viable:", sum(lines$viable == 1), "\n")
cat("Nonviable:", sum(lines$viable == 0), "\n")
cat("Output:", output_path, "\n")

cat("\nD10.11 rendering: PASSED\n")
