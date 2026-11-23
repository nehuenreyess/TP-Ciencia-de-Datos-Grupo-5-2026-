# Porcentaje del Theil explicado por diferencias entre grupos.
# Usa descomponer_theil(), que tiene que estar cargada antes.

pct_theil_entre <- function(x, grupo) {
  d <- descomponer_theil(x, rep(1, length(x)), grupo)
  100 * d$t_entre / d$t_observado
}
