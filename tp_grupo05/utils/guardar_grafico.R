# Guarda un gráfico en output/graficos/ a 300 dpi.
# showtext tiene que usar el mismo dpi que el archivo.

guardar_grafico <- function(grafico, archivo, ancho_cm = 22, alto_cm = 13) {
  showtext_opts(dpi = 300)
  ggsave(file.path("output", "graficos", archivo), grafico,
         width = ancho_cm, height = alto_cm, units = "cm", dpi = 300, bg = "white")
  showtext_opts(dpi = 96)
}
