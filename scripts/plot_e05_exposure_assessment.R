library(ggplot2)

input_path <- "outputs/e05_directional_assessment.csv"
stopifnot(file.exists(input_path))

df <- read.csv(input_path, stringsAsFactors = FALSE)

stopifnot(
  nrow(df) == 108,
  all(c(
    "deg", "seg", "high_fraction",
    "reconstructed_viable"
  ) %in% names(df))
)

# Order bearings and segments for plotting.
bearing_levels <- sort(unique(df$deg))
df$bearing_index <- match(df$deg, bearing_levels)

seg_levels <- c("seg1", "seg2", "seg3")
stopifnot(all(sort(unique(df$seg)) == seg_levels))

df$seg <- factor(df$seg, levels = seg_levels)

# Radial layout: 3 consecutive 2 km segments.
ring_map <- data.frame(
  seg = factor(seg_levels, levels = seg_levels),
  ymin = c(0, 2, 4),
  ymax = c(2, 4, 6)
)

df <- merge(df, ring_map, by = "seg", sort = FALSE)

# One angular bin per 10-degree bearing.
df$xmin <- df$bearing_index - 0.5
df$xmax <- df$bearing_index + 0.5

# Border styling for viability.
df$border_colour <- ifelse(df$reconstructed_viable == 1, "viable", "nonviable")
df$border_size <- ifelse(df$reconstructed_viable == 1, 0.7, 0.25)

output_path <- "outputs/figures/e05_exposure_assessment.png"

p <- ggplot(
  df,
  aes(
    xmin = xmin, xmax = xmax,
    ymin = ymin, ymax = ymax,
    fill = high_fraction
  )
) +
  geom_rect(
    aes(colour = border_colour, linewidth = border_size),
    show.legend = c(fill = TRUE, colour = FALSE, linewidth = FALSE)
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
    low = "grey90",
    high = "firebrick",
    limits = c(0, 1),
    name = "High-exposure\nsupport"
  ) +
  scale_colour_manual(
    name = "Baseline\nclassification",
    values = c(
      viable = "black",
      nonviable = "grey35"
    ),
    labels = c(
      nonviable = "Nonviable",
      viable = "Viable"
    )
  ) +
  scale_linewidth_identity() +
  labs(
    title = "E05 baseline directional exposure assessment",
    subtitle = "Continuous high-exposure support at Te = 0.60; borders show baseline viability at Tv = 0.80",
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
cat("Viable segments:", sum(df$reconstructed_viable == 1), "\n")
cat("Nonviable segments:", sum(df$reconstructed_viable == 0), "\n")
cat("Mean high-exposure support:", round(mean(df$high_fraction), 5), "\n")
cat("E05 exposure figure: PASSED\n")
