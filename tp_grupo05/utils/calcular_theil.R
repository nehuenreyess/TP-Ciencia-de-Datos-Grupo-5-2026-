# Índice de Theil (clase 12)
# x: variable (salario); w: ponderadores (si no hay, todos valen 1)

calcular_theil <- function(x, w = NULL) {
  x <- as.numeric(x)
  if (is.null(w)) w <- rep(1, length(x))
  w <- as.numeric(w)

  ok <- !is.na(x) & !is.na(w) & w > 0 & x > 0
  x <- x[ok]; w <- w[ok]

  w_rel <- w / sum(w)
  media <- sum(x * w_rel)
  ratio <- x / media

  sum(w_rel * ratio * log(ratio))
}
