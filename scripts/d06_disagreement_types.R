# D06.13 — Classification disagreement by fuel/special status

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

fuel <- c("conifer", "mixedwood", "deciduous", "grass")

fuel24 <- pairs$family_2024 %in% fuel
fuel26 <- pairs$family_2026 %in% fuel

different <- pairs$family_2024 != pairs$family_2026

pairs$type <- ifelse(
  !different, "same_family",
  ifelse(
    fuel24 & fuel26, "fuel_to_fuel",
    ifelse(
      xor(fuel24, fuel26), "fuel_to_special",
      "special_to_special"
    )
  )
)

types <- c(
  "same_family",
  "fuel_to_fuel",
  "fuel_to_special",
  "special_to_special"
)

summary <- data.frame(
  type = types,
  cells = vapply(
    types,
    function(type) sum(pairs$cells[pairs$type == type]),
    numeric(1)
  )
)

summary$percent_of_study <- round(
  100 * summary$cells / 40000, 4
)

expected <- c(23934L, 11223L, 3822L, 1021L)

stopifnot(
  identical(as.integer(summary$cells), expected),
  sum(summary$cells) == 40000,
  sum(summary$cells[-1]) == 16066
)

output <- "outputs/tables/d06_disagreement_types.csv"

write.csv(summary, output, row.names = FALSE)

saved <- read.csv(output, stringsAsFactors = FALSE)

stopifnot(
  identical(as.integer(saved$cells), expected),
  identical(saved$type, types)
)

cat("\n=== D06.13: Disagreement types ===\n")
print(summary, row.names = FALSE)

cat("\n=== Different-family composition ===\n")
cat(sprintf(
  "Fuel-to-fuel share: %.2f%%\n",
  100 * summary$cells[2] / 16066
))

cat("\nOutput:", output, "\n")
cat("D06.13 reproducibility: PASSED\n")
