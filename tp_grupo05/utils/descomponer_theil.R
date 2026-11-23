# Descomposición del Theil en desigualdad entre grupos y dentro de los grupos.
# Usa calcular_theil(), que tiene que estar cargada antes.

descomponer_theil <- function(x, w, grupo) {
  x <- as.numeric(x)
  w <- as.numeric(w)

  ok <- !is.na(x) & !is.na(w) & !is.na(grupo) & w > 0 & x > 0
  x <- x[ok]; w <- w[ok]; grupo <- grupo[ok]

  mu_total <- weighted.mean(x, w)
  pob_total <- sum(w)

  detalle <- tibble(grupo = grupo, x = x, w = w) |>
    group_by(grupo) |>
    summarise(
      s_g = sum(w) / pob_total,
      mu_g = weighted.mean(x, w),
      theil_g = calcular_theil(x, w),
      .groups = "drop"
    ) |>
    mutate(
      aporte_entre = s_g * (mu_g / mu_total) * log(mu_g / mu_total),
      aporte_dentro = s_g * (mu_g / mu_total) * theil_g
    )

  list(
    t_observado = calcular_theil(x, w),
    t_entre = sum(detalle$aporte_entre),
    t_dentro = sum(detalle$aporte_dentro),
    detalle = detalle
  )
}
