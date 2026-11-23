# Trabajo Práctico Final — Ciencia de Datos para Economía y Negocios

**Grupo 5 · Facultad de Ciencias Económicas · Universidad de Buenos Aires**

## Integrantes

. Nehuén Federico Reyes Bartulos

. Martina Sendrowicz

. Ezequiel Usle

## Tema
Diferencias salariales entre graduados universitarios e inserción laboral.

## Objetivo
Analizar cómo se relacionan las características educativas y sociodemográficas de las personas graduadas con sus salarios observados, y estudiar si la diferencia salarial entre egresados de instituciones de gestión privada y estatal varía según el tipo de título.

El análisis es observacional. Los resultados describen asociaciones y diferencias entre grupos; no deben interpretarse como efectos causales.

Se plantean tres hipótesis principales:

H1 — Tipo de título: los salarios presentan diferencias entre las distintas categorías de título universitario.

H2 — Gestión y tipo de título: la diferencia salarial entre graduados de instituciones privadas y estatales varía según el tipo de título obtenido.

H3 — Desigualdad: la proporción de desigualdad salarial explicada por diferencias entre grupos es mayor para disciplina y región que para gestión.

## Estructura del repositorio

```text
.
├── README.md
└── tp_grupo05/
    ├── auxiliar/             # Insumos auxiliares
    ├── input/                # Bases procesadas
    ├── output/
    │   ├── tablas/           # Tablas generadas
    │   └── graficos/         # Gráficos generados
    ├── raw/                  # Datos originales y diccionario
    ├── script/               # Scripts de análisis
    ├── utils/                # Funciones auxiliares propias
    └── tp_grupo05.Rproj      # Proyecto de RStudio
```

## Cómo ejecutar el proyecto

Para reproducir el análisis, seguir estos pasos:

1. Descargar o clonar este repositorio.
2. Ingresar en la carpeta `tp_grupo05/`.
3. Abrir el archivo `tp_grupo05.Rproj` con RStudio.
4. Instalar los paquetes necesarios (solo la primera vez):

```r
install.packages(c(
  "tidyverse",
  "readxl",
  "scales",
  "ggtext",
  "showtext",
  "rstatix",
  "lmtest",
  "sandwich"
))
```

5. Abrir el archivo `script/00_correr_todo.R` y presionar **Source** para ejecutar todos los scripts en orden.

También se puede ejecutar directamente desde la consola de RStudio:

```r
source("script/00_correr_todo.R")
```

Los scripts utilizan rutas relativas al directorio del proyecto. Por lo tanto, es necesario abrir `tp_grupo05.Rproj` antes de ejecutar el análisis. No se requiere configurar manualmente el directorio de trabajo mediante `setwd()`.

La ejecución genera automáticamente las bases intermedias en `input/`, las tablas en `output/tablas/` y los gráficos en `output/graficos/`.

## Datos

Los archivos originales necesarios para reproducir el análisis están incluidos en el repositorio, dentro de la carpeta `tp_grupo05/raw/` y `tp_grupo05/auxiliar/`:

- `tp_grupo05/raw/base_araucano.csv.gz`: base de datos original comprimida en formato GZIP.
- `tp_grupo05/auxiliar/diccionario.xlsx`: diccionario de variables y categorías.

La base comprimida se importa directamente desde R, sin necesidad de descomprimirla manualmente.

El diccionario contiene la hoja `cod_disciplina`, utilizada para incorporar las etiquetas correspondientes a las disciplinas.

No es necesario descargar archivos adicionales ni modificar las rutas de acceso para ejecutar los scripts.

## Métodos

El trabajo combina herramientas descriptivas e inferenciales:
- análisis de datos faltantes y detección de valores extremos;
- comparación de distribuciones y medias entre grupos (ANOVA y alternativas robustas/no paramétricas);
- modelos de regresión con interacción entre tipo de título y gestión institucional, con errores estándar robustos;
- medidas de desigualdad y descomposición del índice de Theil.

## Alcances y limitaciones

- El salario se observa para una parte de los registros; la ausencia de salario no debe interpretarse automáticamente como un dato perdido al azar.
- Los salarios nominales de distintos años no son directamente comparables sin considerar la inflación.
- Los métodos de detección de valores extremos identifican observaciones inusuales, pero no demuestran por sí solos que sean errores.
- Las asociaciones estimadas no identifican causalidad.

## Reproducibilidad

El script principal ejecuta los módulos de preparación, descriptivas, diagnóstico de faltantes y outliers, análisis inferencial, regresiones y desigualdad.

Los archivos intermedios se guardan en input/, mientras que las tablas y los gráficos generados se guardan en output/tablas/ y output/graficos/, respectivamente.

Para reproducir el análisis, alcanza con descargar el repositorio, abrir el proyecto de RStudio y ejecutar script/00_correr_todo.R.

## Fuente de datos

**Base utilizada:** Graduados universitarios del sistema Araucano (2016-2018).

**Fuente original:** [Datos Argentina - Graduados universitarios del sistema Araucano](https://datos.produccion.gob.ar/dataset/graduados-universitarios-del-sistema-araucano-2016-2018)

**Período de información sociolaboral:** 2019-2021.

**Unidad de observación:** persona-año. Cada graduado cuenta con tres registros, correspondientes a los años 2019, 2020 y 2021.
