library(ggplot2)

input_path <- "outputs/e05_directional_assessment.csv"
stopifnot(file.exists(input_path))

df <- read.csv(input_path, stringsAsFactors = FALSE)

stopifnot(
  nrow(df) == 108,
  all(c(
    "deg", "seg", "viable_fraction",
    "reconstructed_viable"
  ) %in% names(df))
)

bearing_levels <- sort(unique(df$deg))
df$bearing_index <- match(df$deg, bearing_levels)

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

df$border_colour <- ifelse(df$reconstructed_viable == 1, "viable", "nonviable")
df$border_size <- ifelse(df$reconstructed_viable == 1, 0.7, 0.25)

output_path <- "outputs/figures/e05_threshold_stability.png"

p <- ggplot(
  df,
  aes(
    xmin = xmin, xmax = xmax,
    ymin = ymin, ymax = ymax,
    fill = viable_fraction
  )
) +
  geom_rect(
    colour = "grey45",
    linewidth = 0.25
  ) +
  coord_polar(theta = "x", start = 0, direction = 1, clip = "off") +
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
    high = "navy",
    limits = c(0, 1),
    name = "Threshold-grid\nviable fraction"
  ) +
  labs(
    title = "E05 directional threshold stability",
    subtitle = "Fraction of 72 threshold combinations producing a viable classification",
    caption = "Synthetic heterogeneous exposure surface. Three concentric 2 km segments per bearing."
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.major = element_line(colour = "grey85", linewidth = 0.25),
    panel.grid.minor = element_blank(),
    axis.title = element_blank(),
    plot.title = element_text(face = "bold"),
    legend.position = "right",
    plot.title.position = "plot"
  )

ggsave(
  filename = output_path,
  plot = p,
  width = 8,
  height = 8,
  dpi = 200
)

cat("Figure written to:\n")
cat(output_path, "\n")
cat("Rows plotted:", nrow(df), "\n")
cat("Mean viable fraction:", round(mean(df$viable_fraction), 5), "\n")
cat("Min viable fraction:", round(min(df$viable_fraction), 5), "\n")
cat("Max viable fraction:", round(max(df$viable_fraction), 5), "\n")
cat("E05 threshold stability figure: PASSED\n")
