# Estadísticas descriptivas del salario por grupo.

resumen_salario <- function(base, ...) {
  base |>
    group_by(...) |>
    summarise(
      n = n(),
      media = mean(salario),
      mediana = median(salario),
      desvio = sd(salario),
      cv = desvio / media,
      minimo = min(salario),
      q1 = quantile(salario, 0.25),
      q3 = quantile(salario, 0.75),
      maximo = max(salario),
      .groups = "drop"
    )
}
