library(terra)

cat("\n=== D06.1: Paired 2024–2026 FBP comparison ===\n")

root <- "data/processed/study-window"

r24 <- rast(file.path(root, "fbp_2024_aligned_100m.tif"))
r26 <- rast(file.path(root, "fbp_2026_candidate_100m.tif"))

register24 <- read.csv(
  "docs/datasets/fbp-2024-code-register.csv",
  stringsAsFactors = FALSE
)

register26 <- read.csv(
  "docs/datasets/fbp-2026-code-register.csv",
  stringsAsFactors = FALSE
)

stopifnot(
  compareGeom(r24, r26, stopOnError = FALSE),
  ncell(r24) == 40000,
  ncell(r26) == 40000,
  !anyDuplicated(register24$value),
  !anyDuplicated(register26$value)
)

a <- as.integer(values(r24, mat = FALSE))
b <- as.integer(values(r26, mat = FALSE))

stopifnot(
  length(a) == length(b),
  all(!is.na(a)),
  all(!is.na(b)),
  all(a %in% register24$value),
  all(b %in% register26$value)
)

codes24 <- sort(unique(a))
codes26 <- sort(unique(b))

cat("\n=== Raster geometry ===\n")
cat("Paired cells:", length(a), "\n")
cat("2024 observed codes:", length(codes24), "\n")
cat("2026 observed codes:", length(codes26), "\n")

# Keep every 2024 x 2026 combination, including zero counts.
tab <- table(
  factor(a, levels = codes24),
  factor(b, levels = codes26)
)

pairs <- expand.grid(
  code_2024 = codes24,
  code_2026 = codes26
)

pairs$cells <- as.integer(tab)

pairs$percent_of_study <- round(
  100 * pairs$cells / length(a), 4
)

pairs$meaning_2024 <- register24$meaning[
  match(pairs$code_2024, register24$value)
]

pairs$meaning_2026 <- register26$meaning[
  match(pairs$code_2026, register26$value)
]

pairs$numeric_relation <- ifelse(
  pairs$code_2024 == pairs$code_2026,
  "same_code",
  "different_code"
)

# This is a literal comparison of documented descriptions,
# not a claim that the underlying fuel types are equivalent.
pairs$description_relation <- ifelse(
  pairs$meaning_2024 == pairs$meaning_2026,
  "identical_text",
  "different_text"
)

stopifnot(
  nrow(pairs) == length(codes24) * length(codes26),
  sum(pairs$cells) == 40000,
  !anyNA(pairs)
)

output <- "outputs/tables/d06_fbp_2024_2026_cross_tab.csv"

write.csv(
  pairs,
  output,
  row.names = FALSE,
  na = ""
)

cat("\n=== Numeric comparison ===\n")

same <- sum(a == b)
different <- sum(a != b)

cat("Same numeric code:", same, "\n")
cat("Different numeric code:", different, "\n")

cat(sprintf(
  "Numeric agreement: %.2f%%\n",
  100 * same / length(a)
))

cat(sprintf(
  "Numeric disagreement: %.2f%%\n",
  100 * different / length(a)
))

cat("\n=== Same-code 13 diagnostic ===\n")

same13 <- sum(a == 13 & b == 13)

cat("Both products use code 13:", same13, "\n")

cat("2024 description:",
    register24$meaning[register24$value == 13], "\n")

cat("2026 description:",
    register26$meaning[register26$value == 13], "\n")

cat("\n=== Ten largest classification pairs ===\n")

ranked <- pairs[order(-pairs$cells), ]

print(
  head(
    ranked[, c(
      "code_2024",
      "code_2026",
      "cells",
      "percent_of_study",
      "numeric_relation"
    )],
    10
  ),
  row.names = FALSE
)

cat("\n=== Five largest differing-code pairs ===\n")

different_pairs <- ranked[
  ranked$numeric_relation == "different_code",
]

print(
  head(
    different_pairs[, c(
      "code_2024",
      "meaning_2024",
      "code_2026",
      "meaning_2026",
      "cells"
    )],
    5
  ),
  row.names = FALSE
)

cat("\n=== Output verification ===\n")

saved <- read.csv(output, stringsAsFactors = FALSE)

stopifnot(
  nrow(saved) == nrow(pairs),
  sum(saved$cells) == 40000,
  sum(saved$cells[saved$code_2024 == saved$code_2026]) == same
)

cat("CSV:", output, "\n")
cat("Cross-tabulation rows:", nrow(saved), "\n")
cat("Cell-count reconciliation: PASSED\n")
cat("D06.1 paired classification analysis: PASSED\n")
