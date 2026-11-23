# Coeficiente de Gini (clase 12)
# x: variable (salario); w: ponderadores (si no hay, todos valen 1)

calcular_gini <- function(x, w = NULL) {
  x <- as.numeric(x)
  if (is.null(w)) w <- rep(1, length(x))
  w <- as.numeric(w)

  ok <- !is.na(x) & !is.na(w) & w > 0
  x <- x[ok]; w <- w[ok]

  orden <- order(x)
  x <- x[orden]; w <- w[orden]

  prop_unidades <- cumsum(w) / sum(w)
  prop_magnitud <- cumsum(x * w) / sum(x * w)

  area <- sum(diff(c(0, prop_unidades)) *
                (c(0, head(prop_magnitud, -1)) + prop_magnitud) / 2)

  1 - 2 * area
}
