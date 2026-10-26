library(terra)

cat("\n=== D06.7: Spatial classification disagreement ===\n")

r24 <- rast(
  "data/processed/study-window/fbp_2024_aligned_100m.tif"
)

r26 <- rast(
  "data/processed/study-window/fbp_2026_candidate_100m.tif"
)

summary <- read.csv(
  "outputs/tables/d06_fbp_family_summary.csv",
  stringsAsFactors = FALSE
)

stopifnot(
  compareGeom(r24, r26, stopOnError = FALSE),
  ncell(r24) == 40000
)

family24 <- c(
  "2"="conifer", "3"="conifer", "4"="conifer",
  "11"="deciduous", "13"="deciduous",
  "31"="grass", "101"="non_fuel", "102"="water",
  "105"="vegetated_non_fuel",
  "415"="mixedwood", "625"="mixedwood",
  "650"="mixedwood", "675"="mixedwood"
)

family26 <- c(
  "1"="conifer", "2"="conifer", "3"="conifer",
  "4"="conifer", "11"="deciduous",
  "13"="unmatched_vegetation",
  "31"="grass", "101"="non_fuel", "102"="water",
  "625"="mixedwood", "650"="mixedwood",
  "675"="mixedwood"
)

a <- as.integer(values(r24, mat = FALSE))
b <- as.integer(values(r26, mat = FALSE))

fa <- unname(family24[as.character(a)])
fb <- unname(family26[as.character(b)])

stopifnot(
  !anyNA(a), !anyNA(b),
  !anyNA(fa), !anyNA(fb)
)

same_code <- a == b
same_family <- fa == fb

# Codes:
# 1 = same code, same family
# 2 = different code, same family
# 3 = same code, different family
# 4 = different code, different family

category <- ifelse(
  same_code & same_family, 1L,
  ifelse(
    !same_code & same_family, 2L,
    ifelse(same_code & !same_family, 3L, 4L)
  )
)

observed <- tabulate(category, nbins = 4)

expected_names <- c(
  "same_code_same_family",
  "different_code_same_family",
  "same_code_different_family",
  "different_code_different_family"
)

expected <- summary$cells[
  match(expected_names, summary$category)
]

stopifnot(
  !anyNA(expected),
  identical(as.integer(observed), as.integer(expected)),
  sum(observed) == 40000
)

cat("\n=== Spatial category counts ===\n")

print(
  data.frame(
    category = expected_names,
    cells = observed,
    percent = round(100 * observed / 40000, 4)
  ),
  row.names = FALSE
)

mapped <- r26
values(mapped) <- category
names(mapped) <- "disagreement_category"

raster_path <- paste0(
  "data/processed/study-window/",
  "d06_fbp_disagreement_category_100m.tif"
)

figure_path <- "outputs/figures/d06_fbp_disagreement_map.png"

dir.create(dirname(raster_path),
           recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(figure_path),
           recursive = TRUE, showWarnings = FALSE)

writeRaster(
  mapped, raster_path,
  overwrite = TRUE,
  datatype = "INT1U",
  gdal = "COMPRESS=LZW"
)

colors <- c(
  "#4F8A72",
  "#D9B45F",
  "#9077AC",
  "#C66E59"
)

labels <- c(
  "Same code, same family",
  "Different code, same family",
  "Same code, different family",
  "Different code, different family"
)

png(figure_path, width = 2400, height = 2000, res = 200)

layout(
  matrix(c(1, 2), nrow = 2),
  heights = c(8, 2)
)

par(mar = c(3, 3, 3, 2))

plot(
  mapped,
  col = colors,
  breaks = seq(0.5, 4.5, by = 1),
  legend = FALSE,
  axes = FALSE,
  main = "FBP classification disagreement: 2024 vs 2026"
)

box()

par(mar = c(0, 2, 1, 2))

plot.new()

legend(
  "center",
  legend = sprintf(
    "%s (%.2f%%)",
    labels,
    100 * observed / 40000
  ),
  fill = colors,
  border = NA,
  bty = "n",
  ncol = 2,
  cex = 0.85
)

dev.off()

saved <- rast(raster_path)
saved_values <- as.integer(values(saved, mat = FALSE))

stopifnot(
  compareGeom(saved, r26, stopOnError = FALSE),
  identical(
    as.integer(tabulate(saved_values, nbins = 4)),
    as.integer(observed)
  ),
  !anyNA(saved_values),
  file.exists(figure_path),
  file.info(figure_path)$size > 10000
)

cat("\n=== Saved outputs ===\n")
cat("Raster:", raster_path, "\n")
cat("Figure:", figure_path, "\n")
cat("Figure bytes:", file.info(figure_path)$size, "\n")

cat("\nD06.7 spatial disagreement map: PASSED\n")
