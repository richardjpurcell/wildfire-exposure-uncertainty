library(terra)

reference_path <- paste0(
  "data/processed/study-window/",
  "fbp_2026_candidate_100m.tif"
)

evidence_dir <- "data/processed/provincial-evidence"
output_dir <- "outputs/figures"

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

fbp <- rast(reference_path)

read_evidence <- function(name) {
  path <- file.path(evidence_dir, paste0(name, "_100m.tif"))
  stopifnot(file.exists(path))
  rast(path)
}

named <- read_evidence("named_species")
unclassified <- read_evidence("unclassified_species")
no_description <- read_evidence("no_first_story_description")

for (r in list(named, unclassified, no_description)) {
  stopifnot(compareGeom(fbp, r, stopOnError = FALSE))
}

# Group verified numeric codes into broad display families.
# These are presentation categories, not new FBP assignments.
code_to_family <- c(
  "1"   = 1,
  "2"   = 1,
  "3"   = 1,
  "4"   = 1,
  "625" = 2,
  "650" = 2,
  "675" = 2,
  "11"  = 3,
  "31"  = 4,
  "101" = 5,
  "102" = 6,
  "13"  = 7
)

family_labels <- c(
  "Conifer FBP (C-1 to C-4)",
  "Mixedwood FBP (25/50/75)",
  "Deciduous FBP (D-1)",
  "Grass FBP (O-1a)",
  "Non-fuel",
  "Water",
  "Vegetated, no FBP match"
)

family_colors <- c(
  "#426B50",
  "#A88D45",
  "#91B87A",
  "#D1C77D",
  "#A9A9A5",
  "#78AEC8",
  "#BB83A8"
)

original_codes <- values(fbp, mat = FALSE)
mapped <- unname(code_to_family[as.character(original_codes)])

stopifnot(
  length(mapped) == ncell(fbp),
  !anyNA(mapped),
  setequal(as.integer(unique(mapped)), 1:7)
)

family <- rast(fbp)
values(family) <- as.integer(mapped)
names(family) <- "FBP_family"

coverage_colors <- colorRampPalette(
  c("#FFFFFF", "#DCE6E3", "#7DABA0", "#24594C")
)(100)

output <- file.path(
  output_dir,
  "d03_federal_provincial_comparison.png"
)

png(output, width = 3400, height = 1250, res = 200)

layout(
  matrix(
    c(1, 2, 3, 4,
      5, 5, 5, 5),
    nrow = 2,
    byrow = TRUE
  ),
  heights = c(6, 1)
)

par(
  mar = c(3, 3, 3.8, 1.8),
  oma = c(3.5, 1, 2.5, 1),
  cex.axis = 0.75
)

plot(
  family,
  col = family_colors,
  breaks = seq(0.5, 7.5, by = 1),
  legend = FALSE,
  main = "A. Federal FBP fuel families",
  axes = TRUE
)

evidence <- list(
  "B. Named species" = named,
  "C. Unclassified species" = unclassified,
  "D. No first-story description" = no_description
)

for (label in names(evidence)) {
  plot(
    evidence[[label]],
    col = coverage_colors,
    range = c(0, 1),
    main = label,
    axes = TRUE,
    plg = list(
      title = "Coverage",
      shrink = 0.7
    )
  )
}

# Dedicated legend row below all four maps.
par(mar = c(0, 0, 0, 0))
plot.new()

legend(
  "center",
  legend = family_labels,
  fill = family_colors,
  ncol = 4,
  cex = 0.85,
  bty = "n",
  x.intersp = 0.7,
  y.intersp = 1.1
)

mtext(
  "Federal fuel classification and provincial inventory evidence",
  side = 3,
  outer = TRUE,
  line = 0.5,
  font = 2,
  cex = 1.15
)

mtext(
  "Common 100 m grid | Federal panel groups fuel codes; provincial panels show fractional coverage",
  side = 1,
  outer = TRUE,
  line = 0.6,
  cex = 0.85
)

dev.off()

cat("\n=== D03 federal-provincial comparison ===\n")
cat("Saved:", output, "\n")
cat("Panels: 4\n")
cat("Federal display categories:", length(family_labels), "\n")
cat("Original FBP codes:", length(unique(original_codes)), "\n")

cat("\n=== Federal family cell counts ===\n")
print(
  data.frame(
    family = family_labels,
    cells = as.integer(tabulate(mapped, nbins = 7))
  ),
  row.names = FALSE
)

cat("\nComparison figure generation: COMPLETE\n")
