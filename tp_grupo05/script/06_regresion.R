# 06 - Inferencia: regresión lineal
# a) Interacción entre tipo de título y gestión.
# b) Regresión múltiple con controles por características observadas.

library(tidyverse)
library(scales)
library(ggtext)
library(showtext)
library(lmtest)
library(sandwich)

source("utils/num.R")
source("utils/pintar.R")
source("utils/paleta.R")
source("utils/configurar_fuentes.R")
source("utils/theme_tp.R")
source("utils/guardar_grafico.R")

fuentes <- configurar_fuentes()
base <- read_rds("input/base_salarios.rds")
base_foco <- base |> filter(anio == 2021)

# a) Regresión con interacción.
e1 <- lm(log_salario ~ tipo_titulo + gestion, data = base_foco)
e2 <- lm(log_salario ~ tipo_titulo * gestion, data = base_foco)

bp_e2 <- bptest(e2)
bp_e2

coef_e2 <- coeftest(e2, vcov = vcovHC(e2, type = "HC1"))
coef_e2

test_f <- anova(e1, e2)
test_robust <- waldtest(e1, e2, vcov = vcovHC(e2, type = "HC1"))

tests_interaccion <- tibble(
  prueba = c("Breusch-Pagan (modelo con interacción)", "Test F conjunto",
             "Test de Wald con errores robustos"),
  estadistico = c(unname(bp_e2$statistic), test_f$F[2], test_robust$F[2]),
  p_valor = c(bp_e2$p.value, test_f[["Pr(>F)"]][2], test_robust[["Pr(>F)"]][2]),
  r2_sin_interaccion = summary(e1)$r.squared,
  r2_con_interaccion = summary(e2)$r.squared
)
tests_interaccion

# Brecha privada-estatal por tipo de título.
b2 <- coef(e2)
niveles <- levels(base_foco$tipo_titulo)
brecha_log <- c(b2["gestionPrivada"],
                b2["gestionPrivada"] +
                  b2[paste0("tipo_titulo", niveles[-1], ":gestionPrivada")])
brecha_titulo <- tibble(tipo_titulo = niveles,
                        brecha_pct = 100 * (exp(brecha_log) - 1))
brecha_titulo

# b) Regresión múltiple. Rama se omite porque es redundante con disciplina.
variables_modelo <- c("disciplina", "region", "tipo_titulo", "genero", "gestion")
m_completo <- lm(reformulate(variables_modelo, "log_salario"), data = base_foco)
r2_completo <- summary(m_completo)$r.squared
bp_completo <- bptest(m_completo)
bp_completo

coef_completo <- coeftest(m_completo, vcov = vcovHC(m_completo, type = "HC1"))
tabla_coeficientes <- tibble(
  termino = rownames(coef_completo),
  estimacion = coef_completo[, 1],
  error_est_robusto = coef_completo[, 2],
  t = coef_completo[, 3],
  p_valor = coef_completo[, 4],
  efecto_pct = 100 * (exp(coef_completo[, 1]) - 1)
)
tabla_coeficientes |> filter(!str_starts(termino, "disciplina"))

# Aporte de cada variable: caída del R² al excluirla del modelo completo.
aporte_r2 <- tibble(variable = variables_modelo) |>
  mutate(
    r2_sola = map_dbl(variable, \(v)
      summary(lm(reformulate(v, "log_salario"), data = base_foco))$r.squared),
    r2_sin = map_dbl(variable, \(v)
      summary(lm(reformulate(setdiff(variables_modelo, v), "log_salario"),
                 data = base_foco))$r.squared),
    aporte = r2_completo - r2_sin
  ) |>
  arrange(desc(aporte))
aporte_r2

# Brechas brutas y ajustadas.
comparaciones <- tribble(
  ~comparacion, ~variable, ~coeficiente,
  "Privada vs. estatal", "gestion", "gestionPrivada",
  "Varón vs. mujer", "genero", "generoVarón",
  "Posgrado vs. pregrado", "tipo_titulo", "tipo_tituloPosgrado",
  "NOA vs. CABA", "region", "regionNOA"
)

brechas <- comparaciones |>
  mutate(
    bruta = map2_dbl(variable, coeficiente, \(v, cf)
      coef(lm(reformulate(v, "log_salario"), data = base_foco))[[cf]]),
    ajustada = coef(m_completo)[coeficiente],
    bruta_pct = 100 * (exp(bruta) - 1),
    ajustada_pct = 100 * (exp(ajustada) - 1)
  )
brechas

brecha_privada <- brechas |> filter(variable == "gestion")

g07 <- brechas |>
  mutate(comparacion = factor(comparacion, levels = rev(comparacion))) |>
  ggplot(aes(y = comparacion)) +
  geom_vline(xintercept = 0, color = gris_suave) +
  geom_segment(aes(x = bruta_pct, xend = ajustada_pct, yend = comparacion),
               color = "gray70", linewidth = 1.2) +
  geom_point(aes(x = bruta_pct), color = gris_suave, size = 3.5) +
  geom_point(aes(x = ajustada_pct), color = col_destaque, size = 3.5) +
  geom_text(aes(x = bruta_pct, label = paste0(num(bruta_pct, 1), "%")),
            vjust = -1.2, size = 3.2, color = gris_texto, family = fuentes$texto) +
  geom_text(aes(x = ajustada_pct, label = paste0(num(ajustada_pct, 1), "%")),
            vjust = -1.2, size = 3.2, color = col_destaque, fontface = "bold",
            family = fuentes$texto) +
  scale_x_continuous(limits = c(-50, 75), breaks = seq(-50, 75, 25),
                     labels = \(x) paste0(ifelse(x > 0, "+", ""), x, "%")) +
  labs(
    title = paste0("Al controlar por las demás características, la brecha a favor de las privadas pasa de ",
                   num(brecha_privada$bruta_pct, 1), "% a ",
                   pintar(paste0(num(brecha_privada$ajustada_pct, 1), "%"), col_destaque)),
    subtitle = str_wrap(paste0("Diferencia bruta (gris) y ajustada (naranja), a partir de regresiones del ",
                               "log del salario, para graduados con empleo asalariado registrado en 2021."),
                        width = 115),
    x = "Diferencia en el salario (%)",
    y = NULL,
    caption = str_wrap(paste0("Diferencias calculadas como exp(coeficiente) - 1. R² del modelo completo: ",
                              num(r2_completo, 3), ". Errores estándar robustos (HC1). ", fuente_datos),
                       width = 135)
  ) +
  theme_tp(fuentes) +
  theme(panel.grid.major.y = element_blank(),
        axis.text.y = element_text(size = rel(1.1), color = gris_titulo))

g07
guardar_grafico(g07, "g07_brechas_brutas_ajustadas.png", ancho_cm = 22, alto_cm = 12)

# Anexo: aporte de cada variable al R².
nombres_variables <- c(disciplina = "Disciplina", region = "Región",
                       tipo_titulo = "Tipo de título", genero = "Género",
                       gestion = "Gestión")

a02 <- aporte_r2 |>
  mutate(variable = reorder(nombres_variables[variable], aporte)) |>
  ggplot(aes(x = 100 * aporte, y = variable)) +
  geom_col(fill = col_estatal, width = 0.7) +
  geom_text(aes(label = paste0(num(100 * aporte, 1), " p.p.")), hjust = -0.15, size = 3.2,
            color = gris_texto, family = fuentes$texto) +
  scale_x_continuous(limits = c(0, 8), labels = \(x) paste0(x, " p.p.")) +
  labs(
    title = "Cuánto baja el R² al sacar cada variable del modelo",
    subtitle = paste0("Regresión múltiple del log del salario, 2021. R² del modelo completo: ",
                      num(r2_completo, 3), "."),
    x = "Caída del R² (puntos porcentuales)", y = NULL,
    caption = fuente_datos
  ) +
  theme_tp(fuentes) +
  theme(panel.grid.major.y = element_blank())

a02
guardar_grafico(a02, "a02_aporte_r2.png", ancho_cm = 18, alto_cm = 10)

tabla_interaccion <- tibble(
  termino = rownames(coef_e2),
  estimacion = coef_e2[, 1],
  error_est_robusto = coef_e2[, 2],
  t = coef_e2[, 3],
  p_valor = coef_e2[, 4]
)
write_csv(tabla_interaccion, "output/tablas/06_interaccion_coeficientes.csv")
write_csv(tests_interaccion, "output/tablas/06_interaccion_tests.csv")
write_csv(brecha_titulo, "output/tablas/06_brecha_gestion_por_titulo.csv")
write_csv(tabla_coeficientes, "output/tablas/06_multiple_coeficientes.csv")
write_csv(aporte_r2, "output/tablas/06_multiple_aporte_r2.csv")
write_csv(brechas, "output/tablas/06_brechas_brutas_ajustadas.csv")
