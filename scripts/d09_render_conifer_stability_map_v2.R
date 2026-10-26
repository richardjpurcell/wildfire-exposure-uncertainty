# D09.14 — Conifer-assumption stability map
#
# Render a cartographic companion picture using the same
# geographic extent and annotations as the reference
# exposure map, but showing a three-way classification:
# opposing / agreeing / indeterminate.

library(terra)
library(sf)
library(maptiles)

cat("\n=== D09.14: Conifer stability map ===\n")

a_lower <- rast(
  "data/processed/visualization/d09_scenario_A_delta_lower_500m.tif"
)
a_upper <- rast(
  "data/processed/visualization/d09_scenario_A_delta_upper_500m.tif"
)
b_lower <- rast(
  "data/processed/visualization/d09_scenario_B_delta_lower_500m.tif"
)
b_upper <- rast(
  "data/processed/visualization/d09_scenario_B_delta_upper_500m.tif"
)

stopifnot(
  compareGeom(a_lower, a_upper, stopOnError = FALSE),
  compareGeom(a_lower, b_lower, stopOnError = FALSE),
  compareGeom(a_lower, b_upper, stopOnError = FALSE)
)

tol <- 1e-6

va <- values(a_lower, mat = FALSE)
vb <- values(a_upper, mat = FALSE)
vc <- values(b_lower, mat = FALSE)
vd <- values(b_upper, mat = FALSE)

valid <- is.finite(va) & is.finite(vb) & is.finite(vc) & is.finite(vd)

opposing <- valid & (
  (va > tol & vd < -tol) |
  (vb < -tol & vc > tol)
)

agreeing <- valid & (
  (va > tol & vc > tol) |
  (vb < -tol & vd < -tol)
)

indeterminate <- valid & !opposing & !agreeing

stopifnot(
  sum(valid) == 36100,
  sum(opposing) == 19436,
  sum(agreeing) == 10561,
  sum(indeterminate) == 6103
)

cls <- a_lower
x <- rep(NA_integer_, ncell(cls))
x[indeterminate] <- 1
x[agreeing] <- 2
x[opposing] <- 3
values(cls) <- x

view <- ext(
  2409800, 2415800,
  118123.97736665001, 126123.97736665001
)

cls_view <- crop(cls, view)

points_path <- "data/processed/study-window/reference_points.gpkg"
reference_points <- st_read(points_path, quiet = TRUE)
westwood <- reference_points[
  reference_points$location == "Westwood Hills", ,
  drop = FALSE
]

stopifnot(nrow(westwood) == 1)

westwood <- st_transform(westwood, 3978)
westwood_xy <- st_coordinates(westwood)

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

block_labels <- data.frame(
  block_id = c(35, 44, 25),
  x = c(2413800, 2411800, 2413800),
  y = c(122124, 120124, 124124)
)

# Local check using the known block extents.
xy <- xyFromCell(a_lower, seq_len(ncell(a_lower)))
block_id <- rep(NA_integer_, ncell(a_lower))

assign_block <- function(id, xmin, xmax, ymin, ymax) {
  xy[,1] >= xmin & xy[,1] < xmax &
    xy[,2] >= ymin & xy[,2] < ymax
}

block_id[assign_block(35, 2412800, 2414800, 121124, 123124)] <- 35
block_id[assign_block(44, 2410800, 2412800, 119124, 121124)] <- 44
block_id[assign_block(25, 2412800, 2414800, 123124, 125124)] <- 25

stopifnot(
  sum(opposing & block_id == 35, na.rm = TRUE) == 187,
  sum(opposing & block_id == 44, na.rm = TRUE) == 232,
  sum(opposing & block_id == 25, na.rm = TRUE) == 93
)

window_sf <- st_as_sf(
  as.polygons(view, crs = crs(a_lower))
)

cache_dir <- "data/cache/d09_basemaps"
output_dir <- "outputs/figures"

dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

cat("Retrieving cartographic basemap...\n")

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
  same.crs(tiles, cls_view)
)

# Muted overlay colours with transparency.
fill_cols <- adjustcolor(
  c("#E3DDD1", "#438879", "#B85D4E"),
  alpha.f = 0.80
)

out <- file.path(
  output_dir,
  "d09_conifer_stability_map_v2.png"
)

png(out, width = 1800, height = 2400, res = 200)

tryCatch({

  par(mar = c(2.6, 0.3, 1.7, 0.3))

  # Neutral grayscale cartographic background.
  grey <- (
    0.299 * tiles[[1]] +
    0.587 * tiles[[2]] +
    0.114 * tiles[[3]]
  )

  neutral_tiles <- c(grey, grey, grey)

  plotRGB(
    neutral_tiles,
    r = 1, g = 2, b = 3,
    ext = view,
    axes = FALSE
  )

  plot(
    cls_view,
    add = TRUE,
    ext = view,
    col = fill_cols,
    breaks = c(0.5, 1.5, 2.5, 3.5),
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
    main = "Assumption sensitivity | Edition comparison",
    cex.main = 1.1,
    line = 0.2
  )

  legend(
    "topright",
    inset = 0.02,
    legend = c(
      "Direction unresolved",
      "Same direction",
      "Opposing directions"
    ),
    fill = fill_cols,
    title = "2026 minus 2024",
    bg = "white",
    cex = 0.75,
    bty = "o"
  )

  legend(
    "bottomleft",
    inset = 0.02,
    legend = c("Selected neighbourhood", "Reference point"),
    lwd = c(2, NA),
    pch = c(NA, 21),
    pt.bg = c(NA, "deepskyblue"),
    pt.cex = c(NA, 1.2),
    col = c("black", "black"),
    bg = "white",
    cex = 0.75,
    bty = "o"
  )

  mtext(
    "Map data: OpenStreetMap contributors",
    side = 1,
    line = 1.1,
    cex = 0.60
  )

}, finally = {
  dev.off()
})

stopifnot(
  file.exists(out),
  file.info(out)$size > 10000
)

cat("\n=== Verified results ===\n")
cat("Valid cells:", sum(valid), "\n")
cat("Opposing:", sum(opposing), "\n")
cat("Agreeing:", sum(agreeing), "\n")
cat("Indeterminate:", sum(indeterminate), "\n")
cat("Block 35 opposing:", sum(opposing & block_id == 35, na.rm = TRUE), "\n")
cat("Block 44 opposing:", sum(opposing & block_id == 44, na.rm = TRUE), "\n")
cat("Block 25 opposing:", sum(opposing & block_id == 25, na.rm = TRUE), "\n")
cat("Saved:", out, "\n")

cat("\nD09.14 rendering: PASSED\n")
