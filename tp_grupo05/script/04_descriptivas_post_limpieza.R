# 04 - Estadísticas descriptivas después de la limpieza
# Compara el salario antes y después de excluir los outliers bajos.

library(tidyverse)
library(scales)
library(ggtext)
library(showtext)

source("utils/resumen_salario.R")
source("utils/num.R")
source("utils/pintar.R")
source("utils/paleta.R")
source("utils/configurar_fuentes.R")
source("utils/theme_tp.R")
source("utils/guardar_grafico.R")

fuentes <- configurar_fuentes()

antes <- read_rds("input/base_etiquetada.rds") |> filter(!is.na(salario))
despues <- read_rds("input/base_salarios.rds")
limites <- read_csv("output/tablas/03_limites_outliers.csv", show_col_types = FALSE)

desc_antes <- resumen_salario(antes, anio) |> mutate(momento = "antes")
desc_despues <- resumen_salario(despues, anio) |> mutate(momento = "despues")

comparacion <- bind_rows(desc_antes, desc_despues) |>
  pivot_longer(c(n, media, mediana, desvio, cv, minimo, q1, q3, maximo),
               names_to = "estadistico", values_to = "valor") |>
  pivot_wider(names_from = momento, values_from = valor) |>
  mutate(cambio_pct = 100 * (despues / antes - 1))

nombres_estadisticos <- c(n = "Cantidad de casos", media = "Media", mediana = "Mediana",
                          desvio = "Desvío estándar", cv = "Coef. de variación",
                          q1 = "Primer cuartil (Q1)", q3 = "Tercer cuartil (Q3)")

g05 <- comparacion |>
  filter(estadistico %in% names(nombres_estadisticos)) |>
  mutate(estadistico = factor(nombres_estadisticos[estadistico],
                              levels = rev(nombres_estadisticos)),
         anio = factor(anio)) |>
  ggplot(aes(x = cambio_pct, y = estadistico, color = anio)) +
  geom_vline(xintercept = 0, color = gris_suave) +
  geom_point(size = 3) +
  scale_color_manual(values = c("2019" = "#A9BEDD", "2020" = "#6F8DBF", "2021" = "#2E4A7A")) +
  scale_x_continuous(limits = c(-6, 8), breaks = seq(-6, 8, 2),
                     labels = \(x) paste0(ifelse(x > 0, "+", ""), x, "%")) +
  labs(
    title = "Excluir los salarios atípicamente bajos modifica poco<br>los estadísticos centrales",
    subtitle = str_wrap(paste0("Cambio porcentual de cada estadístico después de excluir los valores ",
                               "extremos bajos, respecto de la base con todos los salarios registrados."),
                        width = 115),
    x = "Cambio respecto de antes de la limpieza (%)",
    y = NULL,
    color = "Año",
    caption = str_wrap(paste0("No se muestra el mínimo, que cambia sustancialmente por la exclusión; el máximo ",
                              "se mantiene. Límites por año: entre $", num(min(limites$lim_inf_pesos)),
                              " y $", num(max(limites$lim_inf_pesos)), ". ", fuente_datos),
                       width = 135)
  ) +
  theme_tp(fuentes) +
  theme(legend.position = "top", legend.justification = "left",
        panel.grid.major.y = element_line(color = "#EEEEEE"))

g05
guardar_grafico(g05, "g05_efecto_limpieza.png", ancho_cm = 22, alto_cm = 12)

write_csv(desc_despues, "output/tablas/04_descriptivas_salario_despues.csv")
write_csv(comparacion, "output/tablas/04_comparacion_antes_despues.csv")
