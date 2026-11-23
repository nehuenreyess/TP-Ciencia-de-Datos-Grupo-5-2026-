# Tema común de los gráficos, basado en theme_owid() de la clase 24.

theme_tp <- function(fuentes, base_size = 11) {
  theme_minimal(base_size = base_size, base_family = fuentes$texto) +
    theme(
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.title = element_markdown(family = fuentes$titulo, size = rel(1.6),
                                    color = gris_titulo, lineheight = 1.1,
                                    margin = margin(b = 6)),
      plot.subtitle = element_text(size = rel(1), color = gris_texto,
                                   lineheight = 1.2, margin = margin(b = 12)),
      plot.caption = element_text(size = rel(0.8), color = gris_suave, hjust = 0,
                                  lineheight = 1.2, margin = margin(t = 12)),
      panel.grid.minor = element_blank(),
      axis.text = element_text(color = "#666666"),
      axis.title = element_text(color = gris_texto, face = "bold"),
      strip.text = element_text(face = "bold", size = rel(1.05), color = gris_titulo),
      legend.position = "none",
      plot.background = element_rect(fill = "white", color = NA),
      plot.margin = margin(15, 18, 12, 15)
    )
}
