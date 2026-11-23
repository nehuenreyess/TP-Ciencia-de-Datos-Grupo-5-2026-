# 02 - Estadísticas descriptivas iniciales (antes de la limpieza)

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
base <- read_rds("input/base_etiquetada.rds")

# Dimensiones: cada graduado aparece una vez por año.
dimensiones <- tibble(
  filas = nrow(base),
  personas = n_distinct(base$id),
  variables = ncol(base),
  anios = paste(range(base$anio), collapse = "-"),
  con_salario = sum(!is.na(base$salario))
)
dimensiones

# Salarios nominales: comparar grupos dentro del año, no entre años.
desc_salario <- base |>
  filter(!is.na(salario)) |>
  resumen_salario(anio)
desc_salario

# Edad.
desc_edad <- base |>
  filter(!is.na(edad)) |>
  group_by(anio) |>
  summarise(n = n(), media = mean(edad), mediana = median(edad), desvio = sd(edad),
            minimo = min(edad), q1 = quantile(edad, 0.25), q3 = quantile(edad, 0.75),
            maximo = max(edad), .groups = "drop")
desc_edad

# Composición: usamos 2021 para contar a cada graduado una sola vez.
composicion <- base |>
  filter(anio == 2021) |>
  select(tipo_titulo, gestion, genero, region, rama) |>
  mutate(across(everything(), as.character)) |>
  pivot_longer(everything(), names_to = "variable", values_to = "categoria") |>
  count(variable, categoria) |>
  group_by(variable) |>
  mutate(pct = 100 * n / sum(n)) |>
  ungroup()
composicion

# Gráfico 1: distribución del salario en 2021.
salario_2021 <- base |> filter(anio == 2021, !is.na(salario), salario > 0)
media_2021 <- mean(salario_2021$salario)
mediana_2021 <- median(salario_2021$salario)

g01 <- salario_2021 |>
  ggplot(aes(x = salario)) +
  geom_histogram(bins = 80, fill = col_estatal, color = "white", linewidth = 0.1) +
  geom_vline(xintercept = mediana_2021, color = gris_titulo, linetype = "dashed") +
  geom_vline(xintercept = media_2021, color = col_destaque, linewidth = 0.8) +
  annotate("text", x = mediana_2021, y = Inf, vjust = 1.5, hjust = 1.05,
           label = paste0("Mediana: $", num(mediana_2021)), color = gris_titulo,
           size = 3.3, family = fuentes$texto) +
  annotate("text", x = media_2021, y = Inf, vjust = 1.5, hjust = -0.05,
           label = paste0("Media: $", num(media_2021)), color = col_destaque,
           size = 3.3, fontface = "bold", family = fuentes$texto) +
  scale_x_log10(breaks = c(1, 100, 1e4, 1e6),
                labels = c("$1", "$100", "$10.000", "$1.000.000")) +
  scale_y_continuous(labels = label_number(big.mark = ".", decimal.mark = ",")) +
  labs(
    title = paste0("El salario es muy asimétrico: la ", pintar("media", col_destaque),
                   " supera a la mediana"),
    subtitle = str_wrap(paste0("Distribución del salario bruto de noviembre de 2021, graduados con ",
                               "empleo asalariado registrado. Escala logarítmica en el eje horizontal."),
                        width = 115),
    x = "Salario bruto de noviembre de 2021 (pesos, escala logarítmica)",
    y = "Cantidad de graduados",
    caption = str_wrap(paste0("Antes de excluir los salarios atípicamente bajos. ", fuente_datos),
                       width = 135)
  ) +
  theme_tp(fuentes) +
  theme(panel.grid.major.x = element_blank())

g01
guardar_grafico(g01, "g01_distribucion_salario.png", ancho_cm = 22, alto_cm = 12)

# Gráfico 2: composición por características.
nombres_variables <- c(tipo_titulo = "Tipo de título", gestion = "Gestión",
                       genero = "Género", region = "Región", rama = "Rama")

g02 <- composicion |>
  mutate(variable = factor(nombres_variables[variable], levels = nombres_variables),
         categoria = reorder(categoria, pct)) |>
  ggplot(aes(x = pct, y = categoria)) +
  geom_col(fill = col_estatal, width = 0.7) +
  geom_text(aes(label = paste0(num(pct, 1), "%")), hjust = -0.15, size = 3,
            color = gris_texto, family = fuentes$texto) +
  facet_wrap(~ variable, scales = "free_y", ncol = 3) +
  scale_x_continuous(limits = c(0, 95), labels = \(x) paste0(x, "%")) +
  labs(
    title = paste0("Siete de cada diez graduados tienen título de grado y<br>",
                   "ocho de cada diez vienen de instituciones estatales"),
    subtitle = str_wrap(paste0("Porcentaje de graduados en cada categoría. Graduados universitarios ",
                               "argentinos con egreso entre 2016 y 2018 (273.445 personas)."),
                        width = 125),
    x = "Porcentaje de graduados",
    y = NULL,
    caption = fuente_datos
  ) +
  theme_tp(fuentes) +
  theme(panel.grid.major.y = element_blank())

g02
guardar_grafico(g02, "g02_composicion.png", ancho_cm = 25, alto_cm = 13)

write_csv(dimensiones, "output/tablas/02_dimensiones.csv")
write_csv(desc_salario, "output/tablas/02_descriptivas_salario_antes.csv")
write_csv(desc_edad, "output/tablas/02_descriptivas_edad.csv")
write_csv(composicion, "output/tablas/02_composicion.csv")
