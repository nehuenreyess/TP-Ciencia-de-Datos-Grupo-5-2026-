# 05 - Inferencia: ANOVA
# Compara el salario según tipo de título y calcula tamaños de efecto.

library(tidyverse)
library(scales)
library(ggtext)
library(showtext)
library(rstatix)

source("utils/eta_cuadrado.R")
source("utils/num.R")
source("utils/pintar.R")
source("utils/paleta.R")
source("utils/configurar_fuentes.R")
source("utils/theme_tp.R")
source("utils/guardar_grafico.R")

fuentes <- configurar_fuentes()
base <- read_rds("input/base_salarios.rds")

# Un solo año: cada graduado aparece una vez y las observaciones son independientes.
anio_foco <- 2021
base_foco <- base |> filter(anio == anio_foco)

# Eta cuadrado de cada característica por año.
eta_por_anio <- base |>
  group_by(anio) |>
  summarise(across(c(disciplina, region, rama, tipo_titulo, genero, gestion),
                   ~ eta_cuadrado(log_salario, .x))) |>
  pivot_longer(-anio, names_to = "variable", values_to = "eta2")

eta_por_anio |>
  pivot_wider(names_from = anio, values_from = eta2) |>
  arrange(desc(.data[["2021"]]))

# ANOVA de un factor: tipo de título.
desc_titulo <- base_foco |>
  group_by(tipo_titulo) |>
  summarise(n = n(), mediana = median(salario), media_log = mean(log_salario),
            sd_log = sd(log_salario), .groups = "drop")
desc_titulo

anova_titulo <- aov(log_salario ~ tipo_titulo, data = base_foco)
summary(anova_titulo)

tabla_anova <- as_tibble(summary(anova_titulo)[[1]], rownames = "termino") |>
  mutate(termino = str_trim(termino),
         eta2 = .data[["Sum Sq"]] / sum(.data[["Sum Sq"]]))
tabla_anova

# Supuestos: un año para independencia; se revisan varianzas y residuos.
cociente_desvios <- max(desc_titulo$sd_log) / min(desc_titulo$sd_log)
cociente_desvios

set.seed(123)
residuos <- tibble(residuo = sample(residuals(anova_titulo), 5000))

a01 <- residuos |>
  ggplot(aes(sample = residuo)) +
  stat_qq(alpha = 0.3, size = 0.8, color = col_estatal) +
  stat_qq_line(color = col_destaque) +
  labs(title = "Residuos del ANOVA por tipo de título frente a una normal",
       subtitle = paste0("Muestra aleatoria de 5.000 residuos, ", anio_foco, "."),
       x = "Cuantiles teóricos de una normal", y = "Cuantiles de los residuos",
       caption = fuente_datos) +
  theme_tp(fuentes)

a01
guardar_grafico(a01, "a01_qq_residuos_anova.png", ancho_cm = 18, alto_cm = 12)

# Contrastes que no requieren igualdad de varianzas o normalidad.
welch <- oneway.test(log_salario ~ tipo_titulo, data = base_foco)
kw <- kruskal.test(salario ~ tipo_titulo, data = base_foco)
welch
kw

pruebas_titulo <- tibble(
  prueba = c("ANOVA", "ANOVA de Welch", "Kruskal-Wallis"),
  estadistico = c(tabla_anova[["F value"]][1], unname(welch$statistic), unname(kw$statistic)),
  gl = c(paste(tabla_anova$Df[1], tabla_anova$Df[2], sep = "; "),
         paste(welch$parameter[1], round(welch$parameter[2]), sep = "; "),
         as.character(kw$parameter)),
  p_valor = c(tabla_anova[["Pr(>F)"]][1], welch$p.value, kw$p.value),
  efecto = c(tabla_anova$eta2[1], NA, unname(kw$statistic) / (nrow(base_foco) - 1)),
  medida_efecto = c("eta²", NA, "épsilon²")
)
pruebas_titulo

games_howell <- games_howell_test(base_foco, log_salario ~ tipo_titulo) |>
  mutate(dif_pct = 100 * (exp(estimate) - 1)) |>
  select(group1, group2, estimate, dif_pct, conf.low, conf.high, p.adj)
games_howell

# Gráfico exploratorio: salario relativo a la mediana de cada año.
base_rel <- base |>
  group_by(anio) |>
  mutate(salario_rel = salario / median(salario)) |>
  ungroup()

medias <- base_rel |>
  group_by(anio, tipo_titulo, gestion) |>
  summarise(media = mean(salario_rel), .groups = "drop")

g06 <- base_rel |>
  ggplot(aes(x = tipo_titulo, y = salario_rel, fill = gestion)) +
  geom_hline(yintercept = 1, linetype = "dashed", color = gris_texto) +
  geom_boxplot(position = position_dodge(width = 0.8), width = 0.7,
               color = "gray25", linewidth = 0.3, alpha = 0.9,
               outlier.size = 0.3, outlier.alpha = 0.2, outlier.color = "gray50") +
  geom_point(data = medias, aes(y = media, group = gestion),
             position = position_dodge(width = 0.8),
             shape = 23, fill = "white", color = "black", size = 1.6) +
  facet_wrap(~ anio, ncol = 3) +
  scale_fill_manual(values = c("Estatal" = col_estatal, "Privada" = col_privada)) +
  scale_y_log10(breaks = c(0.25, 1, 4, 16, 64),
                labels = c("0,25", "1", "4", "16", "64")) +
  coord_flip() +
  labs(
    title = paste0("Salario según tipo de título, en instituciones ",
                   pintar("estatales", col_estatal), " y ",
                   pintar("privadas", col_privada), ", 2019-2021"),
    subtitle = str_wrap(paste0("Salario relativo a la mediana de cada año (1 = mediana del año), ",
                               "para no comparar valores afectados por la inflación. Escala logarítmica."),
                        width = 135),
    x = "Tipo de título",
    y = "Salario relativo a la mediana del año (escala logarítmica)",
    caption = str_wrap(paste0("Caja: 50% central · rombo: media · puntos: valores atípicos · ",
                              "línea punteada: mediana del año. Se excluyen los salarios atípicamente bajos. ",
                              fuente_datos),
                       width = 165)
  ) +
  theme_tp(fuentes) +
  theme(panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(color = "#E5E5E5", linewidth = 0.3),
        panel.spacing.x = unit(14, "pt"))

g06
guardar_grafico(g06, "g06_exploratorio_titulo_gestion.png", ancho_cm = 25, alto_cm = 14)

# Gráfico 9: mediana del salario por tipo de título (diapositiva del ANOVA)
g09 <- desc_titulo |>
  mutate(tipo_titulo = reorder(tipo_titulo, mediana),
         destacado = tipo_titulo == "Posgrado") |>
  ggplot(aes(x = mediana / 1000, y = tipo_titulo, fill = destacado)) +
  geom_col(width = 0.7) +
  geom_text(aes(label = paste0("$", num(mediana))), hjust = -0.1, size = 3.4,
            color = gris_titulo, family = fuentes$texto) +
  scale_fill_manual(values = c("TRUE" = col_destaque, "FALSE" = col_estatal)) +
  scale_x_continuous(limits = c(0, 210), breaks = seq(0, 200, 50),
                     labels = \(x) num(x)) +
  labs(
    title = "La mediana salarial difiere según el tipo de título",
    subtitle = "Salario bruto mediano de noviembre de 2021. Graduados con empleo asalariado registrado.",
    x = "Salario bruto mediano (miles de pesos corrientes)",
    y = NULL,
    caption = str_wrap(paste0("Se excluyen los salarios atípicamente bajos. ", fuente_datos), width = 120)
  ) +
  theme_tp(fuentes) +
  theme(panel.grid.major.y = element_blank())

g09
guardar_grafico(g09, "g09_mediana_por_titulo.png", ancho_cm = 20, alto_cm = 11)

write_csv(eta_por_anio, "output/tablas/05_eta_por_anio.csv")
write_csv(desc_titulo, "output/tablas/05_descriptivas_titulo.csv")
write_csv(tabla_anova, "output/tablas/05_anova_titulo.csv")
write_csv(pruebas_titulo, "output/tablas/05_pruebas_titulo.csv")
write_csv(games_howell, "output/tablas/05_games_howell.csv")
