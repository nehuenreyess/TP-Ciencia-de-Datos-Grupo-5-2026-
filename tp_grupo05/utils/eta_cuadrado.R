# Eta cuadrado: proporción de la variabilidad de y explicada por las diferencias entre grupos.

eta_cuadrado <- function(y, grupo) {
  media_total <- mean(y)
  medias <- tibble(y = y, grupo = grupo) |>
    group_by(grupo) |>
    summarise(n = n(), media = mean(y), .groups = "drop")
  sc_entre <- sum(medias$n * (medias$media - media_total)^2)
  sc_total <- sum((y - media_total)^2)
  sc_entre / sc_total
}
