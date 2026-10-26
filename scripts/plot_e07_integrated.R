# E07: Three views of one synthetic directional assessment

library(ggplot2)
library(grid)

input <- "outputs/e07_integrated_directional_assessment.csv"
output <- "outputs/figures/e07_integrated_three_views.png"

df <- read.csv(input)

required <- c(
  "deg", "seg", "high_fraction",
  "reconstructed_viable", "viable_fraction",
  "coverage_fraction"
)

stopifnot(
  nrow(df) == 108,
  all(required %in% names(df)),
  length(unique(df$deg)) == 36,
  all(df$high_fraction >= 0 & df$high_fraction <= 1),
  all(df$viable_fraction >= 0 & df$viable_fraction <= 1),
  all(df$coverage_fraction >= 0 & df$coverage_fraction <= 1)
)

# Consistent polar geometry across all panels.
bearings <- sort(unique(df$deg))
df$bearing_index <- match(df$deg, bearings)

df$seg <- factor(
  df$seg,
  levels = c("seg1", "seg2", "seg3")
)

rings <- data.frame(
  seg = factor(
    c("seg1", "seg2", "seg3"),
    levels = levels(df$seg)
  ),
  ymin = c(0, 2, 4),
  ymax = c(2, 4, 6)
)

df <- merge(df, rings, by = "seg", sort = FALSE)

df$xmin <- df$bearing_index - 0.5
df$xmax <- df$bearing_index + 0.5

base_plot <- function(fill_column, title, subtitle) {

  ggplot(
    df,
    aes(
      xmin = xmin,
      xmax = xmax,
      ymin = ymin,
      ymax = ymax,
      fill = .data[[fill_column]]
    )
  ) +
    geom_rect(
      colour = "grey55",
      linewidth = 0.22
    ) +
    coord_polar(
      theta = "x",
      start = 0,
      direction = 1,
      clip = "off"
    ) +
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
    labs(
      title = title,
      subtitle = subtitle
    ) +
    theme_minimal(base_size = 11) +
    theme(
      panel.grid.major = element_line(
        colour = "grey85",
        linewidth = 0.25
      ),
      panel.grid.minor = element_blank(),
      axis.title = element_blank(),
      plot.title = element_text(face = "bold", size = 13),
      plot.subtitle = element_text(size = 9),
      legend.position = "bottom",
      legend.key.width = unit(1.3, "cm"),
      plot.margin = margin(12, 10, 10, 10)
    )
}

# A: Baseline high-exposure support.
p_a <- base_plot(
  "high_fraction",
  "A  Exposure assessment",
  "Baseline: Te = 0.60, Tv = 0.80"
) +
  geom_rect(
    data = df[df$reconstructed_viable == 1, ],
    aes(
      xmin = xmin,
      xmax = xmax,
      ymin = ymin,
      ymax = ymax
    ),
    inherit.aes = FALSE,
    fill = NA,
    colour = "black",
    linewidth = 0.75
  ) +
  scale_fill_gradient(
    low = "#F4ECE8",
    high = "#B63D36",
    limits = c(0, 1),
    name = "Exposure support"
  )

# B: Fraction of grid settings producing viable classification.
p_b <- base_plot(
  "viable_fraction",
  "B  Threshold-grid viability",
  "Viable fraction across 72 settings"
) +
  scale_fill_gradient(
    low = "#F0EDF6",
    high = "#58468C",
    limits = c(0, 1),
    name = "Viable fraction"
  )

# C: Nonmissing evidence along each segment.
p_c <- base_plot(
  "coverage_fraction",
  "C  Evidence coverage",
  "Observed fraction of each segment"
) +
  scale_fill_gradient(
    low = "grey92",
    high = "#247665",
    limits = c(0, 1),
    name = "Coverage"
  )

dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)

png(output, width = 3600, height = 1500, res = 200)

grid.newpage()

pushViewport(
  viewport(
    layout = grid.layout(
      nrow = 1,
      ncol = 3
    )
  )
)

plots <- list(p_a, p_b, p_c)

for (i in seq_along(plots)) {
  print(
    plots[[i]],
    newpage = FALSE,
    vp = viewport(
      layout.pos.row = 1,
      layout.pos.col = i
    )
  )
}

dev.off()

stopifnot(file.exists(output))

cat("E07 integrated visualization:", output, "\n")
cat("Directional segments:", nrow(df), "\n")
cat("Baseline viable:", sum(df$reconstructed_viable == 1), "\n")
cat("Baseline nonviable:", sum(df$reconstructed_viable == 0), "\n")
cat("Missing evidence segments:",
    sum(df$coverage_fraction <= 1e-8), "\n")
cat("E07 integrated visualization: PASSED\n")
