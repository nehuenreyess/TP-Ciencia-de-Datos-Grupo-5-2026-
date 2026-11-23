# 01 - Preparación de la base
# Lee la base cruda y el diccionario, agrega las etiquetas de las variables
# categóricas y la edad, y guarda la base en input/.

library(tidyverse)
library(readxl)

# Lectura: acepta el CSV original o el mismo archivo comprimido con gzip.
archivo_base <- if (file.exists("raw/base_araucano.csv")) {
  "raw/base_araucano.csv"
} else if (file.exists("raw/base_araucano.csv.gz")) {
  "raw/base_araucano.csv.gz"
} else {
  stop("No se encuentra la base. Colocá el CSV o el archivo CSV comprimido en raw/.")
}
base_raw <- read_csv(archivo_base, show_col_types = FALSE)

# La disciplina tiene 38 categorías: las traemos del diccionario.
cod_disciplina <- read_excel("raw/diccionario.xlsx", sheet = "cod_disciplina")

dim(base_raw)

# Etiquetas y variables nuevas.
base_etiquetada <- base_raw |>
  left_join(cod_disciplina, by = "disciplina_id") |>
  mutate(
    edad = anio - anionac,
    gestion = factor(gestion_id, levels = 1:2, labels = c("Estatal", "Privada")),
    genero  = factor(genero_id, levels = 1:2, labels = c("Mujer", "Varón")),
    region  = factor(region_id, levels = 1:7,
                     labels = c("CABA", "Buenos Aires", "Resto Pampeana",
                                "NOA", "NEA", "Cuyo", "Patagonia")),
    rama    = factor(rama_id, levels = 1:6,
                     labels = c("Ciencias Sociales", "Ciencias Aplicadas",
                                "Ciencias de la Salud", "Ciencias Humanas",
                                "Ciencias Básicas", "Sin Rama")),
    tipo_titulo = factor(tipo_titulo_id, levels = 1:4,
                         labels = c("Pregrado", "Tecnicatura",
                                    "Grado y profesorado", "Posgrado")),
    disciplina = factor(disciplina)
  )

# Chequeo: el join no debe dejar disciplinas sin etiqueta.
sum(is.na(base_etiquetada$disciplina))

faltantes <- function(x) sum(is.na(x))

tabla_variables <- tribble(
  ~variable,        ~descripcion,                                             ~tipo,
  "salario",        "Remuneración bruta de noviembre (pesos corrientes)",     "Numérica",
  "anio",           "Año de la observación (2019, 2020 o 2021)",              "Numérica",
  "edad",           "Edad en el año de la observación (anio - anionac)",      "Numérica (construida)",
  "tipo_titulo",    "Pregrado, Tecnicatura, Grado y profesorado, Posgrado",   "Categórica (4)",
  "gestion",        "Gestión de la institución: Estatal o Privada",           "Categórica (2)",
  "genero",         "Género: Mujer o Varón",                                  "Categórica (2)",
  "region",         "Región de residencia (7 regiones)",                      "Categórica (7)",
  "rama",           "Rama del conocimiento del título",                       "Categórica (6)",
  "disciplina",     "Disciplina del título",                                  "Categórica (38)"
) |>
  mutate(faltantes = map_int(variable, \(v) faltantes(base_etiquetada[[v]])),
         pct_faltantes = round(100 * faltantes / nrow(base_etiquetada), 1))

tabla_variables

write_rds(base_etiquetada, "input/base_etiquetada.rds")
write_csv(tabla_variables, "output/tablas/01_variables.csv")
