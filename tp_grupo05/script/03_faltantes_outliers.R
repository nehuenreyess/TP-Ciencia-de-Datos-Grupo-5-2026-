# 03 - Valores faltantes y outliers
# Diagnóstico, decisiones de limpieza y armado de la base final.

library(tidyverse)
library(scales)
library(ggtext)
library(showtext)

source("utils/num.R")
source("utils/pintar.R")
source("utils/paleta.R")
source("utils/configurar_fuentes.R")
source("utils/theme_tp.R")
source("utils/guardar_grafico.R")

fuentes <- configurar_fuentes()
base <- read_rds("input/base_etiquetada.rds")

# 1. Faltantes por variable.
tabla_faltantes <- base |>
  select(all_of(c("salario", "tamaño_id", "letra_id", "anionac", "edad",
                  "tipo_titulo", "gestion", "genero", "region", "rama", "disciplina"))) |>
  summarise(across(everything(), ~ sum(is.na(.x)))) |>
  pivot_longer(everything(), names_to = "variable", values_to = "faltantes") |>
  mutate(pct = round(100 * faltantes / nrow(base), 1)) |>
  arrange(desc(faltantes))
tabla_faltantes

# Los faltantes de salario coinciden en gran medida con los de tamaño y letra.
base |>
  summarise(mismas_filas = sum(is.na(salario) & is.na(.data[["tamaño_id"]]) & is.na(letra_id)),
            sin_salario = sum(is.na(salario)))

# 2. Faltantes según características observadas.
pct_sin_salario <- function(datos, variable, nombre) {
  datos |>
    group_by(grupo = as.character({{ variable }})) |>
    summarise(n = n(), pct_sin_salario = 100 * mean(is.na(salario)), .groups = "drop") |>
    mutate(variable = nombre)
}

faltantes_grupo <- bind_rows(
  pct_sin_salario(base, tipo_titulo, "Tipo de título"),
  pct_sin_salario(base, gestion, "Gestión"),
  pct_sin_salario(base, genero, "Género"),
  pct_sin_salario(base, region, "Región"),
  pct_sin_salario(base, rama, "Rama")
)
faltantes_grupo
pct_total <- 100 * mean(is.na(base$salario))

g03 <- faltantes_grupo |>
  ggplot(aes(x = pct_sin_salario, y = reorder(grupo, pct_sin_salario))) +
  geom_col(fill = col_estatal, width = 0.7) +
  geom_vline(xintercept = pct_total, color = col_destaque, linetype = "dashed") +
  geom_text(aes(label = paste0(num(pct_sin_salario), "%")), hjust = -0.15, size = 3,
            color = gris_texto, family = fuentes$texto) +
  facet_wrap(~ variable, scales = "free_y", ncol = 3) +
  scale_x_continuous(limits = c(0, 100), labels = \(x) paste0(x, "%")) +
  labs(
    title = "Los faltantes de salario varían según las características del graduado",
    subtitle = str_wrap(paste0("Porcentaje de filas sin salario registrado según cada característica, 2019-2021. ",
                               "La línea punteada representa el promedio general (", num(pct_total, 1),
                               "%). La ausencia de salario registrado no implica necesariamente desempleo."),
                        width = 138),
    x = "Filas sin salario registrado (%)",
    y = NULL,
    caption = fuente_datos
  ) +
  theme_tp(fuentes) +
  theme(panel.grid.major.y = element_blank())

g03
guardar_grafico(g03, "g03_faltantes_por_grupo.png", ancho_cm = 25, alto_cm = 14)

# Decisión: no se imputa el salario, porque su ausencia indica que no hay
# empleo asalariado registrado observado en AFIP en ese mes. Los resultados
# describen a graduados con empleo asalariado registrado. No se atribuye un
# mecanismo MAR o MNAR concluyente. Los pocos faltantes de edad no se usan
# para definir la muestra de los métodos.

# 3. Outliers: regla IQR sobre log salario, calculada separadamente por año.
con_salario <- base |>
  filter(!is.na(salario), salario > 0) |>
  mutate(log_salario = log(salario))

limites <- con_salario |>
  group_by(anio) |>
  summarise(lim_inf_log = quantile(log_salario, 0.25) - 1.5 * IQR(log_salario),
            lim_sup_log = quantile(log_salario, 0.75) + 1.5 * IQR(log_salario),
            .groups = "drop") |>
  mutate(lim_inf_pesos = exp(lim_inf_log),
         lim_sup_pesos = exp(lim_sup_log))
limites

con_salario <- con_salario |>
  left_join(limites, by = "anio") |>
  mutate(outlier = case_when(
    log_salario < lim_inf_log ~ "Bajo",
    log_salario > lim_sup_log ~ "Alto",
    TRUE ~ "No"
  ))

cantidad_outliers <- con_salario |>
  count(anio, outlier) |>
  group_by(anio) |>
  mutate(pct = 100 * n / sum(n)) |>
  ungroup()
cantidad_outliers

# Gráfico 4: distribución y límites de 2021.
lim_2021 <- limites |> filter(anio == 2021)
pct_bajos_2021 <- cantidad_outliers |>
  filter(anio == 2021, outlier == "Bajo") |>
  pull(pct)

g04 <- con_salario |>
  filter(anio == 2021) |>
  mutate(outlier = factor(outlier, levels = c("Bajo", "No", "Alto"))) |>
  ggplot(aes(x = salario, fill = outlier)) +
  geom_histogram(bins = 80, color = "white", linewidth = 0.1) +
  geom_vline(xintercept = c(lim_2021$lim_inf_pesos, lim_2021$lim_sup_pesos),
             color = gris_titulo, linetype = "dashed") +
  annotate("text", x = lim_2021$lim_inf_pesos, y = Inf, vjust = 1.5, hjust = 1.05,
           label = paste0("Límite inferior:\n$", num(lim_2021$lim_inf_pesos)),
           color = gris_titulo, size = 3.2, lineheight = 0.9, family = fuentes$texto) +
  annotate("text", x = lim_2021$lim_sup_pesos, y = Inf, vjust = 1.5, hjust = -0.05,
           label = paste0("Límite superior:\n$", num(lim_2021$lim_sup_pesos)),
           color = gris_titulo, size = 3.2, lineheight = 0.9, family = fuentes$texto) +
  scale_fill_manual(values = c("Bajo" = col_destaque, "No" = col_gris, "Alto" = col_estatal)) +
  scale_x_log10(breaks = c(1, 100, 1e4, 1e6),
                labels = c("$1", "$100", "$10.000", "$1.000.000")) +
  scale_y_continuous(labels = label_number(big.mark = ".", decimal.mark = ",")) +
  labs(
    title = paste0("Se excluyen los salarios atípicamente bajos (", num(pct_bajos_2021, 1),
                   "%) y se mantienen los altos"),
    subtitle = str_wrap(paste0("Distribución del salario bruto de noviembre de 2021 y límites del rango ",
                               "intercuartílico (Q1 - 1,5 × IQR y Q3 + 1,5 × IQR) sobre el logaritmo. ",
                               "Escala logarítmica en el eje horizontal."),
                        width = 115),
    x = "Salario bruto de noviembre de 2021 (pesos, escala logarítmica)",
    y = "Cantidad de graduados",
    caption = str_wrap(paste0("La regla IQR identifica valores extremos, pero no demuestra por sí sola que sean ",
                              "errores. La decisión de excluir los bajos se interpreta con cautela y los altos ",
                              "se conservan. ", fuente_datos),
                       width = 135)
  ) +
  theme_tp(fuentes) +
  theme(panel.grid.major.x = element_blank())

g04
guardar_grafico(g04, "g04_outliers_salario.png", ancho_cm = 22, alto_cm = 12)

# 4. Muestra analítica: salarios registrados sin extremos bajos.
base_salarios <- con_salario |>
  filter(outlier != "Bajo") |>
  select(id, anio, salario, log_salario, outlier, edad, tipo_titulo, gestion,
         genero, region, rama, disciplina)

nrow(base_salarios)

write_rds(base_salarios, "input/base_salarios.rds")
write_csv(tabla_faltantes, "output/tablas/03_faltantes.csv")
write_csv(faltantes_grupo, "output/tablas/03_faltantes_por_grupo.csv")
write_csv(limites, "output/tablas/03_limites_outliers.csv")
write_csv(cantidad_outliers, "output/tablas/03_cantidad_outliers.csv")
