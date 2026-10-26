# E06: Paired directional evidence-coverage diagrams.

library(ggplot2)

input_path <- "outputs/e06_coverage_comparison.csv"
stopifnot(file.exists(input_path))

df <- read.csv(input_path, stringsAsFactors = FALSE)

stopifnot(
  nrow(df) == 216,
  all(c(
    "deg", "seg", "scenario",
    "coverage_fraction"
  ) %in% names(df))
)

df$scenario <- factor(
  df$scenario,
  levels = c("Measured", "Missing"),
  labels = c(
    "Measured low exposure",
    "Missing western evidence"
  )
)

bearings <- sort(unique(df$deg))
df$bearing_index <- match(df$deg, bearings)

seg_levels <- c("seg1", "seg2", "seg3")
df$seg <- factor(df$seg, levels = seg_levels)

ring_map <- data.frame(
  seg = factor(seg_levels, levels = seg_levels),
  ymin = c(0, 2, 4),
  ymax = c(2, 4, 6)
)

df <- merge(df, ring_map, by = "seg", sort = FALSE)

df$xmin <- df$bearing_index - 0.5
df$xmax <- df$bearing_index + 0.5

output_path <- "outputs/figures/e06_evidence_coverage.png"

dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)

p <- ggplot(
  df,
  aes(
    xmin = xmin,
    xmax = xmax,
    ymin = ymin,
    ymax = ymax,
    fill = coverage_fraction
  )
) +
  geom_rect(
    colour = "grey45",
    linewidth = 0.25
  ) +
  coord_polar(
    theta = "x",
    start = 0,
    direction = 1,
    clip = "off"
  ) +
  facet_wrap(~scenario, nrow = 1) +
  scale_x_continuous(
    breaks = c(9, 18, 27, 36),
    labels = c("E", "S", "W", "N"),
    expand = c(0, 0)
  ) +
  scale_y_continuous(
    breaks = c(2, 4, 6),
    labels = c("2 km", "4 km", "6 km"),
    limits = c(0, 6),
    expand = c(0, 0)
  ) +
  scale_fill_gradient(
    low = "grey92",
    high = "#247665",
    limits = c(0, 1),
    name = "Evidence\ncoverage"
  ) +
  labs(
    title = "E06 directional evidence coverage",
    subtitle = "Identical viability classifications, different evidence availability",
    caption = paste(
      "Synthetic comparison. Coverage is the fraction",
      "of each segment with nonmissing exposure measurements."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.major = element_line(
      colour = "grey85",
      linewidth = 0.25
    ),
    panel.grid.minor = element_blank(),
    axis.title = element_blank(),
    strip.text = element_text(face = "bold"),
    plot.title = element_text(face = "bold"),
    plot.title.position = "plot",
    legend.position = "right"
  )

ggsave(
  filename = output_path,
  plot = p,
  width = 13,
  height = 7,
  dpi = 200
)

cat("Figure written to:\n")
cat(output_path, "\n")
cat("Rows plotted:", nrow(df), "\n")
cat("Scenarios:", nlevels(df$scenario), "\n")
cat("E06 evidence coverage figure: PASSED\n")
