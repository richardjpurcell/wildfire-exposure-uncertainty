# D09.13 — Annotated reference exposure pair
#
# Adds Westwood Hills reference point and selected
# neighbourhood blocks to the revised paired maps.
#
# Uses the same reference exposure surface, extent,
# legend, and basemap distinction as D09.12.

library(terra)
library(sf)
library(maptiles)

cat("\n=== D09.13: Annotated reference exposure pair ===\n")

reference <- rast(
  "data/processed/visualization/d09_reference_exposure_2026_500m.tif"
)

points_path <- "data/processed/study-window/reference_points.gpkg"

stopifnot(file.exists(points_path))

reference_points <- st_read(points_path, quiet = TRUE)

# Keep the named reference point if present.
westwood <- reference_points[
  reference_points$location == "Westwood Hills", ,
  drop = FALSE
]

stopifnot(nrow(westwood) == 1)

view <- ext(
  2409800, 2415800,
  118123.97736665001, 126123.97736665001
)

exposure <- crop(reference, view)

stopifnot(
  nrow(exposure) == 80,
  ncol(exposure) == 60
)

# Convert plotting extent to sf polygon for tile retrieval.
window_sf <- st_as_sf(
  as.polygons(view, crs = crs(reference))
)

# Selected 2 km neighbourhood blocks from D09.7.
make_block <- function(id, xmin, xmax, ymin, ymax) {
  p <- rbind(
    c(xmin, ymin),
    c(xmax, ymin),
    c(xmax, ymax),
    c(xmin, ymax),
    c(xmin, ymin)
  )
  st_sf(
    block_id = id,
    geometry = st_sfc(st_polygon(list(p)), crs = 3978)
  )
}

blocks <- rbind(
  make_block(35, 2412800, 2414800, 121124, 123124),
  make_block(44, 2410800, 2412800, 119124, 121124),
  make_block(25, 2412800, 2414800, 123124, 125124)
)

# Label positions at block centres.
block_centres <- st_centroid(blocks)
coords <- st_coordinates(block_centres)
block_labels <- data.frame(
  block_id = blocks$block_id,
  x = coords[,1],
  y = coords[,2]
)

westwood_xy <- st_coordinates(st_transform(westwood, 3978))

cache_dir <- "data/cache/d09_basemaps"
output_dir <- "outputs/figures"

dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

breaks <- seq(0, 1, by = 0.2)

base_palette <- c(
  "#FEE8C8",
  "#FDBB84",
  "#FC8D59",
  "#E34A33",
  "#B30000"
)

overlay_colours <- adjustcolor(
  base_palette,
  alpha.f = 0.45
)

render <- function(provider, name, title, attribution) {

  cat("\nRendering:", name, "\n")

  tiles <- maptiles::get_tiles(
    x = window_sf,
    provider = provider,
    zoom = 13,
    crop = TRUE,
    project = TRUE,
    cachedir = cache_dir
  )

  stopifnot(
    inherits(tiles, "SpatRaster"),
    nlyr(tiles) >= 3,
    same.crs(tiles, exposure)
  )

  # Grayscale basemap while preserving geographic detail.
  grey <- (
    0.299 * tiles[[1]] +
    0.587 * tiles[[2]] +
    0.114 * tiles[[3]]
  )

  neutral_tiles <- c(grey, grey, grey)

  path <- file.path(
    output_dir,
    paste0("d09_", name, "_exposure_grayscale_45.png")
  )

  png(
    filename = path,
    width = 1800,
    height = 2920,
    res = 200
  )

  tryCatch({

    layout(matrix(c(1, 2), ncol = 1), heights = c(8.5, 2.1))

    par(mar = c(2.6, 0.3, 1.7, 0.3))

    plotRGB(
      neutral_tiles,
      r = 1, g = 2, b = 3,
      ext = view,
      axes = FALSE
    )

    plot(
      exposure,
      add = TRUE,
      ext = view,
      col = overlay_colours,
      breaks = breaks,
      legend = FALSE,
      axes = FALSE,
      colNA = NA,
      reset = FALSE
    )

    plot(
      vect(blocks),
      add = TRUE,
      border = "black",
      lwd = 2
    )

    points(
      westwood_xy[1,1],
      westwood_xy[1,2],
      pch = 21,
      bg = "deepskyblue",
      col = "black",
      cex = 1.3,
      lwd = 1.2
    )

    text(
      westwood_xy[1,1] + 350,
      westwood_xy[1,2] + 250,
      labels = "Westwood Hills",
      cex = 0.85,
      font = 2,
      adj = c(0, 0.5)
    )

    text(
      block_labels$x,
      block_labels$y,
      labels = paste("Block", block_labels$block_id),
      cex = 0.90,
      font = 2
    )

    title(
      main = title,
      cex.main = 1.1,
      line = 0.2
    )





    mtext(
      attribution,
      side = 1,
      line = 1.1,
      cex = 0.60
    )


  # External colour legend and closely spaced map symbols.
  par(mar = c(0, 0, 0, 0))
  plot.new()

  legend(
    x = 0.5,
    y = 0.76,
    legend = c("0.0–0.2", "0.2–0.4", "0.4–0.6", "0.6–0.8", "0.8–1.0"),
    fill = overlay_colours,
    title = "Reference exposure",
    ncol = 2,
    xjust = 0.5,
    yjust = 0.5,
    cex = 1.18,
    x.intersp = 0.72,
    y.intersp = 1.08,
    bty = "n"
  )

  # Explicit positions keep the symbols close to their labels.
  symbols_y <- 0.46

  segments(
    x0 = 0.18,
    y0 = symbols_y,
    x1 = 0.22,
    y1 = symbols_y,
    col = "black",
    lwd = 2
  )

  text(
    x = 0.235,
    y = symbols_y,
    labels = "Selected neighbourhood",
    adj = c(0, 0.5),
    cex = 1.02
  )

  points(
    x = 0.59,
    y = symbols_y,
    pch = 21,
    bg = "deepskyblue",
    col = "black",
    cex = 1.10
  )

  text(
    x = 0.608,
    y = symbols_y,
    labels = "Westwood Hills",
    adj = c(0, 0.5),
    cex = 1.02
  )

}, finally = {
    dev.off()
  })

  stopifnot(
    file.exists(path),
    file.info(path)$size > 10000
  )

  cat("Saved:", path, "\n")
}

render(
  "Esri.WorldImagery",
  "satellite",
  "Reference exposure | Satellite grayscale",
  "Imagery: Esri and contributors"
)

render(
  "OpenStreetMap",
  "cartographic",
  "Reference exposure | Map grayscale",
  "Map data: OpenStreetMap contributors"
)

cat("\n=== Shared rendering settings ===\n")
cat("Opacity: 0.45\n")
cat("Breaks:", paste(breaks, collapse = ", "), "\n")
cat("Annotated blocks: 25, 35, 44\n")
cat("Reference point: Westwood Hills\n")
cat("Output size: 1800 x 2400 pixels\n")

cat("\nD09.13 annotated rendering: PASSED\n")
