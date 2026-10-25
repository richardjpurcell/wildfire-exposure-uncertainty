# E01: Directional classification across an exposure boundary
# Synthetic experiment; no wildfire observations.

library(terra)
library(fireexposuR)

# Study geometry: 20 x 20 km, 100 m cells.
exposure <- rast(
  nrows = 200,
  ncols = 200,
  xmin = 0,
  xmax = 20000,
  ymin = 0,
  ymax = 20000,
  crs = "EPSG:3978"
)

# Construct two exposure regions.
x_coordinate <- init(exposure, "x")

exposure <- ifel(
  x_coordinate < 10000,
  0.40,
  0.75
)

names(exposure) <- "exposure"

# Point at the boundary between regions.
point <- vect(
  "POINT (10000 10000)",
  crs = crs(exposure)
)

# Baseline directional assessment.
directions <- fire_exp_dir(
  exposure = exposure,
  value = point,
  t_lengths = c(2000, 2000, 2000),
  interval = 10,
  thresh_exp = 0.60,
  thresh_viable = 0.80
)

results <- as.data.frame(directions)

cat("E01: Synthetic directional transition\n")
cat("Directional features:", nrow(results), "\n")

cat("\nViability counts:\n")
print(table(results$viable, useNA = "ifany"))

cat("\nViability by segment:\n")
print(table(results$seg, results$viable))

cat("\nSelected bearings:\n")
print(
  results[
    results$deg %in% c(10, 90, 180, 270, 360),
    c("deg", "seg", "viable")
  ]
)

stopifnot(
  nrow(results) == 108,
  !anyNA(results$viable),
  all(results$viable %in% c(0, 1)),
  any(results$viable == 0),
  any(results$viable == 1)
)

# Display classifications across all bearings.
bearing_table <- reshape(
  results[, c("deg", "seg", "viable")],
  idvar = "deg",
  timevar = "seg",
  direction = "wide"
)

bearing_table <- bearing_table[
  order(bearing_table$deg),
]

cat("\nClassification by bearing:\n")
print(bearing_table, row.names = FALSE)

# Inspect geometry for two contrasting bearings.
selected <- directions[
  directions$deg %in% c(90, 270),
]

selected_lengths <- terra::perim(selected)

geometry_check <- data.frame(
  deg = selected$deg,
  seg = selected$seg,
  viable = selected$viable,
  length_m = round(selected_lengths, 2)
)

cat("\nSelected directional geometry:\n")
print(geometry_check, row.names = FALSE)

cat("\nGeometry type:\n")
print(terra::geomtype(selected))

cat("\nE01 initial classification test: PASSED\n")

# E01 continuous support reconstruction

source("R/directional_support.R")

support <- directional_support(
  exposure = exposure,
  transects = directions,
  thresh_exp = 0.60,
  thresh_viable = 0.80
)

# Match results by bearing and segment.
original <- as.data.frame(directions)

comparison <- merge(
  original[, c("deg", "seg", "viable")],
  support,
  by = c("deg", "seg"),
  all = TRUE
)

stopifnot(
  nrow(comparison) == 108,
  !anyNA(comparison$viable),
  !anyNA(comparison$reconstructed_viable)
)

comparison$agreement <-
  comparison$viable == comparison$reconstructed_viable

cat("\nContinuous reconstruction summary:\n")

cat(
  "Matching classifications:",
  sum(comparison$agreement),
  "of",
  nrow(comparison),
  "\n"
)

cat("\nContinuous support by selected bearing:\n")

selected_support <- comparison[
  comparison$deg %in% c(90, 180, 270, 360),
  c(
    "deg",
    "seg",
    "high_fraction",
    "decision_margin",
    "viable",
    "reconstructed_viable"
  )
]

print(
  selected_support[
    order(selected_support$deg, selected_support$seg),
  ],
  row.names = FALSE,
  digits = 5
)

stopifnot(all(comparison$agreement))

cat("\nE01 continuous reconstruction: PASSED\n")
