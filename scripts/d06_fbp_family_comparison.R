# D06.5 — Version-specific broad fuel-family comparison
# Analytical groupings, not official NRCan classifications.

pairs <- read.csv(
  "outputs/tables/d06_fbp_2024_2026_cross_tab.csv",
  stringsAsFactors = FALSE
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

pairs$family_2024 <- unname(
  family24[as.character(pairs$code_2024)]
)
pairs$family_2026 <- unname(
  family26[as.character(pairs$code_2026)]
)

stopifnot(
  nrow(pairs) == 156,
  sum(pairs$cells) == 40000,
  !anyNA(pairs$family_2024),
  !anyNA(pairs$family_2026)
)

same_code <- pairs$code_2024 == pairs$code_2026
same_family <- pairs$family_2024 == pairs$family_2026

pairs$category <- ifelse(
  same_code & same_family,
  "same_code_same_family",
  ifelse(
    same_code & !same_family,
    "same_code_different_family",
    ifelse(
      !same_code & same_family,
      "different_code_same_family",
      "different_code_different_family"
    )
  )
)

categories <- c(
  "same_code_same_family",
  "different_code_same_family",
  "same_code_different_family",
  "different_code_different_family"
)

summary <- data.frame(
  category = categories,
  cells = vapply(
    categories,
    function(x) sum(pairs$cells[pairs$category == x]),
    numeric(1)
  )
)

summary$percent <- round(
  100 * summary$cells / 40000, 4
)

family_table <- aggregate(
  cells ~ family_2024 + family_2026,
  data = pairs,
  FUN = sum
)

family_table <- family_table[
  order(family_table$family_2024,
        family_table$family_2026),
]

rownames(family_table) <- NULL

stopifnot(
  identical(
    as.integer(summary$cells),
    c(16700L, 7234L, 303L, 15763L)
  ),
  sum(family_table$cells) == 40000,
  sum(summary$cells) == 40000
)

write.csv(
  summary,
  "outputs/tables/d06_fbp_family_summary.csv",
  row.names = FALSE
)

write.csv(
  family_table,
  "outputs/tables/d06_fbp_family_cross_tab.csv",
  row.names = FALSE
)

cat("\n=== D06.5: Classification comparison categories ===\n")
print(summary, row.names = FALSE)

cat("\n=== Overall family disagreement ===\n")
different_family <- sum(summary$cells[c(3, 4)])

cat("Different-family cells:", different_family, "\n")
cat(sprintf(
  "Different-family percentage: %.4f%%\n",
  100 * different_family / 40000
))

cat("\n=== Output verification ===\n")

saved_summary <- read.csv(
  "outputs/tables/d06_fbp_family_summary.csv"
)

saved_table <- read.csv(
  "outputs/tables/d06_fbp_family_cross_tab.csv"
)

stopifnot(
  identical(as.integer(saved_summary$cells),
            as.integer(summary$cells)),
  sum(saved_table$cells) == 40000,
  different_family == 16066
)

cat("Summary CSV: PASSED\n")
cat("Family cross-tab CSV: PASSED\n")
cat("D06.5 reproducibility: PASSED\n")
