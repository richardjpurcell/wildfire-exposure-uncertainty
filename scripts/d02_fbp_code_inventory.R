# D02: Inventory observed codes in the 2026 FBP candidate.
# No fuel-type meanings are inferred from numeric values.

library(terra)

input <- "data/processed/study-window/fbp_2026_candidate_100m.tif"
output <- "outputs/d02_fbp_2026_code_counts.csv"

fuel <- rast(input)
counts <- freq(fuel)

stopifnot(nrow(counts) > 0)

names(counts)[names(counts) == "count"] <- "cells"

counts <- counts[, c("value", "cells")]
counts$percent <- 100 * counts$cells / ncell(fuel)
counts <- counts[order(-counts$cells), ]

missing <- global(is.na(fuel), "sum", na.rm = TRUE)[1, 1]

stopifnot(
  sum(counts$cells) + missing == ncell(fuel),
  ncell(fuel) == 40000
)

write.csv(counts, output, row.names = FALSE)

cat("Study cells:", ncell(fuel), "\n")
cat("Observed codes:", nrow(counts), "\n")
cat("Missing cells:", missing, "\n")
cat("Output:", output, "\n")
cat("D02 fuel-code inventory: PASSED\n")
