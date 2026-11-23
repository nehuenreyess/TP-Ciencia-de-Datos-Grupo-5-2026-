# Formato de números en castellano: punto de miles y coma decimal.

num <- function(x, dec = 0) {
  formatC(x, format = "f", digits = dec, big.mark = ".", decimal.mark = ",")
}
