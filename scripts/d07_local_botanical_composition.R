# D07.11 — Local botanical composition
#
# Provincial species-component contributions within
# 2024 C-4 -> 2026 C-2 disagreement cells.
#
# Reuses the D07.10 grid and exact intersection method.
# Botanical groups follow the provincial attribute reference.
# These are inventory descriptions, not FBP fuel types.

library(terra)

cat("\n=== D07.11: Local botanical composition ===\n")

softwood <- c(
  "RS", "BF", "BS", "XS", "WP", "OS",
  "TL", "EH", "WS", "US", "RP", "NS"
)

hardwood <- c(
  "RM", "IH", "UH", "TH", "OH", "YB",
  "WB", "SM", "BE", "RO", "TA", "AS"
)

unresolved <- "UC"

classify <- function(code) {
  ifelse(
    code %in% softwood, "softwood",
    ifelse(
      code %in% hardwood, "hardwood",
      ifelse(code == unresolved, "unresolved", NA_character_)
    )
  )
}

stopifnot(
  !anyDuplicated(c(softwood, hardwood, unresolved))
)

r24 <- rast(
  "data/processed/study-window/fbp_2024_aligned_100m.tif"
)

r26 <- rast(
  "data/processed/study-window/fbp_2026_candidate_100m.tif"
)

stopifnot(
  compareGeom(r24, r26, stopOnError = FALSE),
  nrow(r24) == 200,
  ncol(r24) == 200
)

selected <- values(r24, mat = FALSE) == 4 &
            values(r26, mat = FALSE) == 2

stopifnot(!anyNA(selected), sum(selected) == 3568)

target <- as.polygons(
  ifel(r24 == 4 & r26 == 2, 1, NA),
  dissolve = TRUE,
  na.rm = TRUE
)

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
a$area_ha <- as.numeric(expanse(local, unit = "ha"))

proportion_fields <- paste0("SP", 1:4, "P")

totals <- rowSums(
  as.matrix(a[, proportion_fields, drop = FALSE]),
  na.rm = TRUE
)

stopifnot(all(totals %in% c(0, 10)))

d <- a[totals == 10, , drop = FALSE]

# Convert species proportions (tenths) into area
# contributions while retaining individual codes.

contributions <- lapply(1:4, function(i) {

  codes <- trimws(
    as.character(d[[paste0("SP", i)]])
  )

  p <- d[[paste0("SP", i, "P")]]

  valid <- !is.na(p) & p > 0

  stopifnot(
    all(!is.na(codes[valid])),
    all(nzchar(codes[valid]))
  )

  data.frame(
    block_id = d$block_id[valid],
    species_code = codes[valid],
    weighted_ha = d$area_ha[valid] * p[valid] / 10
  )
})

components <- do.call(rbind, contributions)

components$botanical_group <- classify(
  components$species_code
)

stopifnot(
  !anyNA(components$botanical_group),
  abs(sum(components$weighted_ha) - 2834.208) < 0.1
)

# Validate against D07.11 global botanical grouping.

global <- tapply(
  components$weighted_ha,
  components$botanical_group,
  sum
)

stopifnot(
  abs(global["softwood"] - 2184.150) < 0.1,
  abs(global["hardwood"] - 504.516) < 0.1,
  abs(global["unresolved"] - 145.543) < 0.1
)

# Six local neighbourhoods, including four primary
# candidates and two additional comparison areas.

ids <- c(35, 34, 25, 24, 44, 33)

groups <- data.frame(
  block_id = ids,
  described_ha = numeric(length(ids)),
  softwood_pct = numeric(length(ids)),
  hardwood_pct = numeric(length(ids)),
  unresolved_pct = numeric(length(ids))
)

for (i in seq_along(ids)) {

  x <- components[
    components$block_id == ids[i],
    ,
    drop = FALSE
  ]

  total <- sum(x$weighted_ha)

  stopifnot(total > 0)

  groups$described_ha[i] <- total

  for (group in c("softwood", "hardwood", "unresolved")) {
    field <- paste0(group, "_pct")

    groups[[field]][i] <-
      100 * sum(
        x$weighted_ha[x$botanical_group == group]
      ) / total
  }
}

stopifnot(
  all(abs(
    groups$softwood_pct +
    groups$hardwood_pct +
    groups$unresolved_pct - 100
  ) < 0.001)
)

# Independent comparison with maintained D07.10 totals.

previous <- read.csv(
  "outputs/tables/d07_neighbourhood_evidence.csv"
)

expected <- previous$described_ha[
  match(ids, previous$block_id)
]

stopifnot(
  !anyNA(expected),
  all(abs(groups$described_ha - expected) < 0.01)
)

# Detailed species contribution for four primary areas.

primary <- c(35, 34, 25, 24)

details <- components[
  components$block_id %in% primary,
  ,
  drop = FALSE
]

details <- aggregate(
  weighted_ha ~ block_id + species_code + botanical_group,
  data = details,
  FUN = sum
)

denominators <- groups$described_ha[
  match(details$block_id, groups$block_id)
]

details$percent_described <-
  100 * details$weighted_ha / denominators

details <- details[
  order(
    match(details$block_id, primary),
    -details$weighted_ha,
    details$species_code
  ),
  ,
  drop = FALSE
]

rownames(details) <- NULL

for (id in primary) {
  stopifnot(
    abs(sum(
      details$percent_described[
        details$block_id == id
      ]
    ) - 100) < 0.001
  )
}

# Validate selected exploratory findings.

get_pct <- function(id, code) {
  x <- details[
    details$block_id == id &
    details$species_code == code,
    ,
    drop = FALSE
  ]
  stopifnot(nrow(x) == 1)
  x$percent_described
}

stopifnot(
  abs(get_pct(35, "RS") - 30.238) < 0.1,
  abs(get_pct(34, "XS") - 29.498) < 0.1,
  abs(get_pct(25, "RM") - 23.171) < 0.1,
  abs(get_pct(24, "UC") - 23.807) < 0.1
)

# Write outputs only after all validations pass.

dir.create(
  "outputs/tables",
  recursive = TRUE,
  showWarnings = FALSE
)

write.csv(
  groups,
  "outputs/tables/d07_local_botanical_groups.csv",
  row.names = FALSE
)

write.csv(
  details,
  "outputs/tables/d07_local_species_components.csv",
  row.names = FALSE
)

cat("\n=== Local botanical groups ===\n")
print(groups, row.names = FALSE, digits = 4)

cat("\n=== Primary candidate species contributions ===\n")

for (id in primary) {
  cat("\nNeighbourhood", id, "\n")

  print(
    head(details[details$block_id == id, ], 6),
    row.names = FALSE,
    digits = 4
  )
}

cat("\nD07.11 reproducibility: PASSED\n")
cat("Two CSV files written.\n")
