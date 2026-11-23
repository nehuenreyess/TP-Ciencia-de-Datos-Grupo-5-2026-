# 07 - Análisis cuantitativo de desigualdad salarial: Gini y Theil
# Calcula índices por año y descompone el Theil entre grupos y dentro de ellos.

library(tidyverse)
library(scales)
library(ggtext)
library(showtext)

source("utils/calcular_gini.R")
source("utils/calcular_theil.R")
source("utils/descomponer_theil.R")
source("utils/pct_theil_entre.R")
source("utils/num.R")
source("utils/pintar.R")
source("utils/paleta.R")
source("utils/configurar_fuentes.R")
source("utils/theme_tp.R")
source("utils/guardar_grafico.R")

fuentes <- configurar_fuentes()
con_outliers <- read_rds("input/base_etiquetada.rds") |>
  filter(!is.na(salario), salario > 0)
base <- read_rds("input/base_salarios.rds")

# Gini y Theil por año, con y sin extremos bajos.
gini_theil <- bind_rows(
  con_outliers |>
    group_by(anio) |>
    summarise(gini = calcular_gini(salario), theil = calcular_theil(salario)) |>
    mutate(muestra = "Con outliers bajos"),
  base |>
    group_by(anio) |>
    summarise(gini = calcular_gini(salario), theil = calcular_theil(salario)) |>
    mutate(muestra = "Sin outliers bajos")
)
gini_theil

# Descomposición del Theil por tipo de título; se verifica que cierre.
base_2021 <- base |> filter(anio == 2021)
theil_titulo <- descomponer_theil(base_2021$salario, rep(1, nrow(base_2021)),
                                  base_2021$tipo_titulo)
all.equal(theil_titulo$t_observado, theil_titulo$t_entre + theil_titulo$t_dentro)
theil_titulo$detalle

theil_por_anio <- base |>
  group_by(anio) |>
  summarise(across(c(disciplina, region, rama, tipo_titulo, genero, gestion),
                   ~ pct_theil_entre(salario, .x))) |>
  pivot_longer(-anio, names_to = "variable", values_to = "entre")

theil_por_anio |>
  pivot_wider(names_from = anio, values_from = entre) |>
  arrange(desc(.data[["2021"]]))

maximo_previo <- theil_por_anio |>
  filter(anio < 2021) |>
  pull(entre) |>
  max()

# Gráfico comunicativo de descomposición.
brecha_media <- base_2021 |>
  group_by(gestion) |>
  summarise(media = mean(salario)) |>
  summarise(brecha = 100 * (media[gestion == "Privada"] /
                              media[gestion == "Estatal"] - 1)) |>
  pull(brecha)

nombres_variables <- c(disciplina = "Disciplina", region = "Región",
                       rama = "Rama de estudio", tipo_titulo = "Tipo de título",
                       genero = "Género", gestion = "Gestión (estatal o privada)")

barras <- theil_por_anio |>
  filter(anio == 2021) |>
  arrange(desc(entre)) |>
  mutate(
    dentro = 100 - entre,
    nombre = factor(nombres_variables[variable], levels = nombres_variables[variable]),
    primera = row_number() == 1,
    color_entre = if_else(primera, col_destaque, col_suave),
    color_texto = if_else(primera, col_destaque, gris_titulo),
    etiqueta_entre = if_else(primera, paste0(num(entre, 1), "% entre grupos"),
                             paste0(num(entre, 1), "%")),
    etiqueta_dentro = if_else(primera, paste0(num(dentro, 1), "% dentro de los grupos"),
                              paste0(num(dentro, 1), "%"))
  )

nota_gestion <- paste0("aunque en promedio los graduados de privadas ganan un ",
                       num(brecha_media, 0), "% más")

# Preparación de posiciones verticales.
# La característica con mayor porcentaje queda arriba.

barras_plot <- barras |>
  mutate(y = rev(seq_len(n())))

# Gráfico G08: descomposición del índice de Theil.

g08 <- ggplot() +
  
  # Fondo gris: desigualdad dentro de los grupos.
  geom_rect(
    data = barras_plot,
    aes(
      xmin = 0,
      xmax = 100,
      ymin = y - 0.34,
      ymax = y + 0.34
    ),
    fill = col_gris,
    color = "white",
    linewidth = 0.8
  ) +
  
  # Segmento naranja: desigualdad entre grupos.
  geom_rect(
    data = barras_plot,
    aes(
      xmin = 0,
      xmax = entre,
      ymin = y - 0.34,
      ymax = y + 0.34,
      fill = color_entre
    ),
    color = "white",
    linewidth = 0.8
  ) +
  
  scale_fill_identity() +
  
  # Etiquetas del porcentaje entre grupos.
  geom_text(
    data = barras_plot,
    aes(
      x = entre + 1.2,
      y = y,
      label = etiqueta_entre,
      color = color_texto
    ),
    hjust = 0,
    fontface = "bold",
    size = 3.6,
    family = fuentes$texto
  ) +
  
  scale_color_identity() +
  
  # Etiquetas del porcentaje dentro de los grupos.
  geom_text(
    data = barras_plot,
    aes(
      x = 99,
      y = y,
      label = etiqueta_dentro
    ),
    hjust = 1,
    color = gris_texto,
    size = 3.6,
    family = fuentes$texto
  ) +
  
  # Eje horizontal.
  scale_x_continuous(
    limits = c(0, 100),
    breaks = seq(0, 100, 20),
    labels = \(x) paste0(num(x, 0), "%"),
    expand = c(0, 0)
  ) +
  
  # Eje vertical con las seis características.
  scale_y_continuous(
    breaks = seq_len(nrow(barras_plot)),
    labels = as.character(
      barras_plot$nombre[order(barras_plot$y)]
    ),
    limits = c(0.5, nrow(barras_plot) + 0.5),
    expand = c(0, 0)
  ) +
  
  labs(
    title = paste0(
      "Ninguna característica de los graduados da cuenta de ",
      pintar("más del 9%", col_destaque),
      "<br>de la desigualdad salarial"
    ),
    
    subtitle = str_wrap(
      paste0(
        "Cada barra divide la desigualdad salarial total (índice de Theil, 2021) ",
        "en la parte explicada por diferencias entre grupos y la parte que ocurre ",
        "dentro de cada grupo."
      ),
      width = 115
    ),
    
    x = "Porcentaje de la desigualdad salarial total (índice de Theil)",
    
    y = NULL,
    
    caption = str_wrap(
      paste0(
        "Graduados con empleo asalariado registrado en noviembre de 2021; ",
        "se excluyen los salarios atípicamente bajos. ",
        "En 2019 y 2020 el valor máximo fue de ",
        num(maximo_previo, 1), "%. ",
        "La brecha salarial media entre gestión privada y estatal fue de ",
        num(brecha_media, 0), "%. ",
        fuente_datos
      ),
      width = 135
    )
  ) +
  
  theme_tp(fuentes) +
  
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    
    axis.text.y = element_text(
      color = gris_titulo,
      face = "bold"
    ),
    
    axis.line.x = element_line(
      color = "#999999",
      linewidth = 0.4
    ),
    
    axis.ticks.x = element_line(
      color = "#999999",
      linewidth = 0.4
    ),
    
    axis.title.x = element_text(
      margin = margin(t = 8)
    )
  )

g08
guardar_grafico(g08, "g08_comunicativo_theil.png", ancho_cm = 22, alto_cm = 15)

# Gráfico 11: Gini y Theil por año, con y sin outliers bajos
# El eje vertical empieza en 0: con un eje recortado, cambios de menos de
# 0,01 parecerían grandes.
g11 <- gini_theil |>
  pivot_longer(c(gini, theil), names_to = "indice", values_to = "valor") |>
  mutate(indice = if_else(indice == "gini", "Coeficiente de Gini", "Índice de Theil")) |>
  ggplot(aes(x = factor(anio), y = valor, color = muestra, group = muestra)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  # las dos series están muy cerca: la de arriba (con outliers) lleva la
  # etiqueta arriba y la de abajo (sin outliers), abajo, para que no se pisen
  geom_text(data = \(d) filter(d, muestra == "Con outliers bajos"),
            aes(label = num(valor, 3)), vjust = -1, size = 3.2, show.legend = FALSE,
            family = fuentes$texto) +
  geom_text(data = \(d) filter(d, muestra == "Sin outliers bajos"),
            aes(label = num(valor, 3)), vjust = 2, size = 3.2, show.legend = FALSE,
            family = fuentes$texto) +
  facet_wrap(~ indice, ncol = 2) +
  scale_color_manual(values = c("Sin outliers bajos" = col_destaque,
                                "Con outliers bajos" = gris_suave)) +
  scale_y_continuous(limits = c(0, 0.45), labels = \(x) num(x, 2)) +
  labs(
    title = "La desigualdad salarial casi no cambia entre 2019 y 2021",
    subtitle = str_wrap(paste0("Coeficiente de Gini e índice de Theil del salario bruto de noviembre, por año. ",
                               "Ninguno de los dos índices depende del nivel de precios, por eso se pueden ",
                               "comparar entre años sin deflactar."), width = 115),
    x = NULL,
    y = "Valor del índice",
    color = NULL,
    caption = str_wrap(paste0("Graduados con empleo asalariado registrado. El eje vertical empieza en 0. ",
                              fuente_datos), width = 130)
  ) +
  theme_tp(fuentes) +
  theme(legend.position = "top", legend.justification = "left",
        legend.text = element_text(size = rel(1)),
        panel.grid.major.x = element_blank())

g11
guardar_grafico(g11, "g11_gini_theil_por_anio.png", ancho_cm = 22, alto_cm = 12)

write_csv(gini_theil, "output/tablas/07_gini_theil_por_anio.csv")
write_csv(theil_por_anio, "output/tablas/07_theil_entre_por_anio.csv")
write_csv(theil_titulo$detalle, "output/tablas/07_theil_detalle_titulo_2021.csv")
