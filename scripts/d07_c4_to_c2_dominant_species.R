# D07.9 — Area-weighted first-listed provincial species
# for 2024 C-4 -> 2026 C-2 disagreement cells.
#
# SP1 identifies the largest recorded species component.
# This is not equivalent to a pure stand or an FBP fuel type.

library(terra)

cat("\n=== D07.9: Dominant-species analysis ===\n")

r24 <- rast(
  "data/processed/study-window/fbp_2024_aligned_100m.tif"
)
r26 <- rast(
  "data/processed/study-window/fbp_2026_candidate_100m.tif"
)

stopifnot(compareGeom(r24, r26, stopOnError = FALSE))

selected <- values(r24, mat = FALSE) == 4 &
            values(r26, mat = FALSE) == 2

stopifnot(!anyNA(selected), sum(selected) == 3568)

target <- as.polygons(
  ifel(r24 == 4 & r26 == 2, 1, NA),
  dissolve = TRUE,
  na.rm = TRUE
)

forest <- vect(
  "data/raw/ns-forest-inventory/halifax-west/forest.shp"
)
forest <- forest[forest$LNDCLASS == 99, ]
forest <- project(forest, crs(target))

pieces <- intersect(crop(forest, ext(target)), target)

a <- values(pieces, dataframe = TRUE)
a$area_ha <- as.numeric(expanse(pieces, unit = "ha"))

fields <- paste0("SP", 1:4, "P")
components <- as.matrix(a[, fields, drop = FALSE])
totals <- rowSums(components, na.rm = TRUE)

stopifnot(all(totals %in% c(0, 10)))

described <- totals == 10

stopifnot(
  all(!is.na(a$SP1[described])),
  all(components[described, 1] >=
      apply(components[described, , drop = FALSE], 1, max))
)

d <- a[described, c("SP1", "SP1P", "area_ha")]
total_area <- sum(d$area_ha)

dominant <- aggregate(area_ha ~ SP1, data = d, FUN = sum)
dominant <- dominant[order(-dominant$area_ha), ]
dominant$percent_described <- 100 * dominant$area_ha / total_area
rownames(dominant) <- NULL

mixing <- data.frame(
  category = c(
    "single_component_100_percent",
    "multiple_components",
    "leading_component_50_percent_or_less"
  ),
  area_ha = c(
    sum(d$area_ha[d$SP1P == 10]),
    sum(d$area_ha[d$SP1P < 10]),
    sum(d$area_ha[d$SP1P <= 5])
  )
)

mixing$percent_described <- 100 * mixing$area_ha / total_area

cat("\n=== Leading dominant codes ===\n")
print(head(dominant, 12), row.names = FALSE)

cat("\n=== Stand mixing ===\n")
print(mixing, row.names = FALSE)

cat("\n=== Validation ===\n")

stopifnot(
  abs(total_area - 2834.208) < 0.1,
  abs(sum(dominant$area_ha) - total_area) < 0.01,
  identical(head(dominant$SP1, 5),
            c("RS", "BS", "XS", "BF", "RM")),
  abs(mixing$area_ha[1] - 219.9766) < 0.1,
  abs(mixing$area_ha[3] - 1194.882) < 0.1,
  abs(sum(mixing$area_ha[1:2]) - total_area) < 0.01
)

dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)

write.csv(
  dominant,
  "outputs/tables/d07_c4_to_c2_dominant_species.csv",
  row.names = FALSE
)

write.csv(
  mixing,
  "outputs/tables/d07_c4_to_c2_stand_mixing.csv",
  row.names = FALSE
)

cat("\nD07.9 reproducibility: PASSED\n")
