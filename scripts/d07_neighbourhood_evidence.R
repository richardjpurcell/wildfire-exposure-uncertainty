# D07.10 — Spatially localized provincial evidence
#
# Partition the established 200 x 200, 100 m study grid
# into 100 non-overlapping 2 km neighbourhoods.
#
# Summarize provincial forest inventory evidence only
# within 2024 C-4 -> 2026 C-2 disagreement cells.
#
# All provincial area measurements use exact polygon
# intersection area, not raster-cell counts.
#
# No maps are produced.

library(terra)

cat("\n=== D07.10: Neighbourhood evidence ===\n")

# --------------------------------------------------
# 1. Established national FBP inputs
# --------------------------------------------------

r24 <- rast(
  "data/processed/study-window/fbp_2024_aligned_100m.tif"
)

r26 <- rast(
  "data/processed/study-window/fbp_2026_candidate_100m.tif"
)

stopifnot(
  compareGeom(r24, r26, stopOnError = FALSE),
  nrow(r24) == 200,
  ncol(r24) == 200,
  all(res(r24) == 100)
)

selected <- values(r24, mat = FALSE) == 4 &
            values(r26, mat = FALSE) == 2

stopifnot(
  !anyNA(selected),
  sum(selected) == 3568
)

target <- as.polygons(
  ifel(r24 == 4 & r26 == 2, 1, NA),
  dissolve = TRUE,
  na.rm = TRUE
)

# --------------------------------------------------
# 2. Fixed 2 km neighbourhood grid
# --------------------------------------------------

cells <- seq_len(ncell(r24))

rr <- rowFromCell(r24, cells)
cc <- colFromCell(r24, cells)

block_id <- ((rr - 1) %/% 20) * 10 +
            ((cc - 1) %/% 20) + 1

block_raster <- r24
values(block_raster) <- block_id
names(block_raster) <- "block_id"

blocks <- as.polygons(
  block_raster,
  dissolve = TRUE,
  na.rm = TRUE
)

stopifnot(nrow(blocks) == 100)

ids <- 1:100

block_row <- (ids - 1) %/% 10 + 1
block_col <- (ids - 1) %% 10 + 1

centre_x <- xmin(r24) +
            (block_col - 0.5) * 2000

centre_y <- ymax(r24) -
            (block_row - 0.5) * 2000

result <- data.frame(
  block_id = ids,
  block_row = block_row,
  block_col = block_col,
  centre_x_3978 = centre_x,
  centre_y_3978 = centre_y,
  disagreement_cells = tabulate(
    block_id[selected],
    nbins = 100
  )
)

result$disagreement_pct <-
  100 * result$disagreement_cells / 400

# --------------------------------------------------
# 3. Reference-point distances
# --------------------------------------------------

refs <- vect(
  "data/processed/study-window/reference_points.gpkg"
)

refs <- project(refs, crs(r24))

ref_names <- values(refs, dataframe = TRUE)$location
ref_xy <- crds(refs)

stopifnot(
  sum(ref_names == "Westwood Hills") == 1,
  sum(ref_names == "Upper Tantallon") == 1
)

distance_to <- function(name) {
  xy <- ref_xy[which(ref_names == name), ]

  sqrt(
    (centre_x - xy[1])^2 +
    (centre_y - xy[2])^2
  ) / 1000
}

result$westwood_distance_km <-
  distance_to("Westwood Hills")

result$tantallon_distance_km <-
  distance_to("Upper Tantallon")

# --------------------------------------------------
# 4. Provincial forest intersection
# --------------------------------------------------

forest <- vect(
  "data/raw/ns-forest-inventory/halifax-west/forest.shp"
)

forest <- forest[forest$LNDCLASS == 99, ]

forest <- project(forest, crs(target))

pieces <- intersect(
  crop(forest, ext(target)),
  target
)

local <- intersect(pieces, blocks)

a <- values(local, dataframe = TRUE)

a$area_ha <- as.numeric(
  expanse(local, unit = "ha")
)

fields <- paste0("SP", 1:4, "P")

components <- as.matrix(
  a[, fields, drop = FALSE]
)

totals <- rowSums(
  components,
  na.rm = TRUE
)

stopifnot(all(totals %in% c(0, 10)))

a$described <- totals == 10

# --------------------------------------------------
# 5. Initialize provincial evidence fields
# --------------------------------------------------

result$forest_ha <- 0
result$described_ha <- 0
result$undescribed_ha <- 0

result$forest_coverage_pct <- NA_real_
result$description_pct <- NA_real_

result$leading_species <- NA_character_
result$leading_species_pct <- NA_real_

result$multiple_components_pct <- NA_real_
result$leading_50_or_less_pct <- NA_real_

result$photo_1992_ha <- 0
result$photo_2003_ha <- 0
result$photo_1992_2003_pct <- NA_real_
result$photo_missing_pct <- NA_real_

result$photo_years <- NA_character_

# --------------------------------------------------
# 6. Summarize each neighbourhood
# --------------------------------------------------

for (id in ids) {

  x <- a[
    a$block_id == id,
    ,
    drop = FALSE
  ]

  if (nrow(x) == 0) next

  forest_area <- sum(x$area_ha)

  d <- x[
    x$described,
    ,
    drop = FALSE
  ]

  described_area <- sum(d$area_ha)

  result$forest_ha[id] <- forest_area
  result$described_ha[id] <- described_area

  result$undescribed_ha[id] <-
    forest_area - described_area

  result$description_pct[id] <-
    100 * described_area / forest_area

  if (nrow(d) == 0) next

  stopifnot(
    all(!is.na(d$SP1)),
    all(!is.na(d$SP1P))
  )

  species <- aggregate(
    area_ha ~ SP1,
    data = d,
    FUN = sum
  )

  species <- species[
    order(-species$area_ha, species$SP1),
    ,
    drop = FALSE
  ]

  result$leading_species[id] <-
    as.character(species$SP1[1])

  result$leading_species_pct[id] <-
    100 * species$area_ha[1] / described_area

  result$multiple_components_pct[id] <-
    100 * sum(
      d$area_ha[d$SP1P < 10]
    ) / described_area

  result$leading_50_or_less_pct[id] <-
    100 * sum(
      d$area_ha[d$SP1P <= 5]
    ) / described_area

  # PHOTOYR is an inventory source-year field.
  # Missing values remain distinct from dated records.

  years <- trimws(as.character(d$PHOTOYR))

  missing <- is.na(years) |
             years == "" |
             years == "0"

  years[missing] <- "MISSING"

  result$photo_1992_ha[id] <-
    sum(d$area_ha[years == "1992"])

  result$photo_2003_ha[id] <-
    sum(d$area_ha[years == "2003"])

  result$photo_1992_2003_pct[id] <-
    100 * sum(
      d$area_ha[years %in% c("1992", "2003")]
    ) / described_area

  result$photo_missing_pct[id] <-
    100 * sum(
      d$area_ha[years == "MISSING"]
    ) / described_area

  result$photo_years[id] <- paste(
    sort(unique(years)),
    collapse = ";"
  )
}

# --------------------------------------------------
# 7. Forest coverage of disagreement footprint
# --------------------------------------------------

active <- result$disagreement_cells > 0

result$forest_coverage_pct[active] <-
  100 * result$forest_ha[active] /
  result$disagreement_cells[active]

# --------------------------------------------------
# 8. Reproducibility validation
# --------------------------------------------------

stopifnot(
  nrow(result) == 100,
  sum(result$disagreement_cells) == 3568,
  abs(sum(result$forest_ha) - 3040.746) < 0.1,
  abs(sum(result$described_ha) - 2834.208) < 0.1,
  abs(sum(result$undescribed_ha) - 206.538) < 0.1
)

stopifnot(
  all(result$forest_ha >= 0),
  all(result$described_ha >= 0),
  all(result$undescribed_ha >= -1e-7),
  all(result$described_ha <=
      result$forest_ha + 1e-7)
)

# Validate previously examined neighbourhoods.

check <- function(id, field, expected, tolerance = 0.1) {
  actual <- result[[field]][id]

  stopifnot(
    !is.na(actual),
    abs(actual - expected) < tolerance
  )
}

check(64, "disagreement_cells", 90)
check(64, "description_pct", 100)
check(64, "leading_species_pct", 49.73)

check(98, "disagreement_cells", 77)
check(98, "leading_species_pct", 99.27)

check(40, "leading_50_or_less_pct", 86.59)

check(71, "description_pct", 67.60)

check(53, "disagreement_cells", 91)

check(35, "westwood_distance_km", 0.259, 0.01)

# --------------------------------------------------
# 9. Output
# --------------------------------------------------

output <- "outputs/tables/d07_neighbourhood_evidence.csv"

dir.create(
  dirname(output),
  recursive = TRUE,
  showWarnings = FALSE
)

write.csv(
  result,
  output,
  row.names = FALSE,
  na = ""
)

cat("\n=== Global validation ===\n")

cat("Neighbourhoods:", nrow(result), "\n")
cat("Disagreement cells:",
    sum(result$disagreement_cells), "\n")

cat("Provincial forest (ha):",
    round(sum(result$forest_ha), 3), "\n")

cat("Described forest (ha):",
    round(sum(result$described_ha), 3), "\n")

cat("Undescribed forest (ha):",
    round(sum(result$undescribed_ha), 3), "\n")

cat("\n=== Westwood Hills neighbourhood ===\n")

print(
  result[result$block_id == 35, ],
  row.names = FALSE
)

cat("\n=== Upper Tantallon neighbourhood ===\n")

print(
  result[result$block_id == 56, ],
  row.names = FALSE
)

cat("\nD07.10 reproducibility: PASSED\n")
cat("Output:", output, "\n")
