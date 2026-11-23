# Pinta un texto de un color para usarlo en títulos con ggtext.

pintar <- function(texto, color) {
  sprintf("<span style='color:%s'><b>%s</b></span>", color, texto)
}
