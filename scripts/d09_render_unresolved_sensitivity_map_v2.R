# D09.16 — Unresolved-input sensitivity map
#
# Uses the verified 2026 upper-minus-lower exposure
# sensitivity raster.
#
# Same extent, annotations, and cartographic background
# as the D09 assumption-sensitivity map.
#
# Visual prototype, not a final figure.

library(terra)
library(sf)
library(maptiles)

cat("\n=== D09.16: Unresolved sensitivity map ===\n")

sensitivity <- rast(
  "data/processed/visualization/d09_unresolved_sensitivity_2026_500m.tif"
)

reference <- rast(
  "data/processed/visualization/d09_reference_exposure_2026_500m.tif"
)

stopifnot(
  compareGeom(sensitivity, reference, stopOnError = FALSE)
)

view <- ext(
  xmin(reference) + 5000,
  xmin(reference) + 11000,
  ymax(reference) - 11000,
  ymax(reference) - 3000
)

sensitivity_view <- crop(sensitivity, view)

v <- values(sensitivity_view, mat = FALSE)

stopifnot(
  nrow(sensitivity_view) == 80,
  ncol(sensitivity_view) == 60,
  all(is.finite(v)),
  all(v >= -1e-6),
  all(v <= 1 + 1e-6)
)

cat("Map cells:", length(v), "\n")
cat("Mean sensitivity:", mean(v), "\n")
cat("Maximum sensitivity:", max(v), "\n")
cat("Affected cells:", sum(v > 1e-6), "\n")

reference_points <- st_read(
  "data/processed/study-window/reference_points.gpkg",
  quiet = TRUE
)

westwood <- reference_points[
  reference_points$location == "Westwood Hills", ,
  drop = FALSE
]

stopifnot(nrow(westwood) == 1)

westwood_xy <- st_coordinates(
  st_transform(westwood, 3978)
)

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

labels <- data.frame(
  id = c(35, 44, 25),
  x = c(2413800, 2411800, 2413800),
  y = c(122124, 120124, 124124)
)

window_sf <- st_as_sf(
  as.polygons(view, crs = crs(reference))
)

cache_dir <- "data/cache/d09_basemaps"
output_dir <- "outputs/figures"

dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

tiles <- maptiles::get_tiles(
  x = window_sf,
  provider = "OpenStreetMap",
  zoom = 13,
  crop = TRUE,
  project = TRUE,
  cachedir = cache_dir
)

stopifnot(
  inherits(tiles, "SpatRaster"),
  nlyr(tiles) >= 3,
  same.crs(tiles, sensitivity_view)
)

# Grayscale background.
grey <- (
  0.299 * tiles[[1]] +
  0.587 * tiles[[2]] +
  0.114 * tiles[[3]]
)

neutral_tiles <- c(grey, grey, grey)

# Separate zero from five positive sensitivity bins.
# Values <= 1e-6 are treated as computational zero.

tol <- 1e-6

classified <- sensitivity_view
values(classified) <- ifelse(
  v <= tol, NA_integer_,
  pmin(5L, ceiling(v / 0.2))
)

breaks <- seq(0.5, 5.5, by = 1)

fill_cols <- adjustcolor(
  c(
    "#E1D7EF",
    "#B7A1D4",
    "#896DB2",
    "#69469B",
    "#452574"
  ),
  alpha.f = 0.80
)

out <- file.path(
  output_dir,
  "d09_unresolved_sensitivity_map_v2.png"
)

png(out, width = 1800, height = 2920, res = 200)

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
    classified,
    add = TRUE,
    ext = view,
    breaks = breaks,
    col = fill_cols,
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
    westwood_xy[1,1] + 380,
    westwood_xy[1,2] + 260,
    "Westwood Hills",
    cex = 0.85,
    font = 2,
    adj = c(0, 0.5)
  )

  text(
    labels$x,
    labels$y,
    paste("Block", labels$id),
    cex = 0.90,
    font = 2
  )

  title(
    main = "Unresolved-input sensitivity | 2026 reference",
    cex.main = 1.05,
    line = 0.2
  )





  mtext(
    "Map data: OpenStreetMap contributors",
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
    legend = c("No sensitivity", ">0–0.2", ">0.2–0.4", ">0.4–0.6", ">0.6–0.8", ">0.8–1.0"),
    fill = c("white", fill_cols),
    title = "Exposure difference",
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
  file.exists(out),
  file.info(out)$size > 10000
)

cat("Saved:", out, "\n")
cat("\nD09.16 rendering: PASSED\n")
