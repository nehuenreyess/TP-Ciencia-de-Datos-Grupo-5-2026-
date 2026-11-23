# Carga las tipografías de los gráficos con showtext.
# Si no hay internet, usa la serif y la sans del sistema.

configurar_fuentes <- function() {
  ok <- tryCatch({
    font_add_google("Playfair Display", "playfair", regular.wt = 600, bold.wt = 700)
    font_add_google("Lato", "lato", regular.wt = 400, bold.wt = 700)
    TRUE
  }, error = function(e) FALSE)

  showtext_auto()
  showtext_opts(dpi = 96)

  list(titulo = if (ok) "playfair" else "serif",
       texto = if (ok) "lato" else "sans")
}
