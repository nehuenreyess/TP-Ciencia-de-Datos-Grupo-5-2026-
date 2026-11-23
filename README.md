# Trabajo Práctico Final — Ciencia de Datos para Economía y Negocios

**Grupo 5 · Facultad de Ciencias Económicas · Universidad de Buenos Aires**

## Integrantes

- Nehuén Federico Reyes Bartulos
- Martina Sendrowicz
- Ezequiel Usle

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
    ├── auxiliar/             # Diccionario de variables
    ├── input/                # Bases procesadas
    ├── output/
    │   ├── tablas/           # Tablas generadas
    │   └── graficos/         # Gráficos generados
    ├── raw/                  # Base original (comprimida)
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
- regresión múltiple con disciplina, región, tipo de título, género y gestión, para comparar brechas brutas y ajustadas;
- medidas de desigualdad y descomposición del índice de Theil.

## Alcances y limitaciones

- El salario se observa para una parte de los registros; la ausencia de salario no debe interpretarse automáticamente como un dato perdido al azar.
- Los salarios nominales de distintos años no son directamente comparables sin considerar la inflación.
- Los métodos de detección de valores extremos identifican observaciones inusuales, pero no demuestran por sí solos que sean errores.
- Las asociaciones estimadas no identifican causalidad.

## Qué hace cada script

| Script | Qué hace | Lee | Genera |
| --- | --- | --- | --- |
| `00_correr_todo.R` | Corre los scripts 01 a 07 en orden | — | Todo lo de abajo |
| `01_preparacion_base.R` | Etiqueta las variables y calcula la edad | `raw/`, `auxiliar/` | `input/base_etiquetada.rds`, `01_variables.csv` |
| `02_descriptivas_iniciales.R` | Descriptivas del salario, la edad y la composición | `input/base_etiquetada.rds` | tablas `02_*`, gráficos `g01`, `g02` |
| `03_faltantes_outliers.R` | Diagnóstico de faltantes y outliers; arma la base del análisis | `input/base_etiquetada.rds` | `input/base_salarios.rds`, tablas `03_*`, gráficos `g03`, `g04` |
| `04_descriptivas_post_limpieza.R` | Compara las descriptivas antes y después de la limpieza | `input/*.rds`, `03_limites_outliers.csv` | tablas `04_*`, gráfico `g05` |
| `05_anova.R` | ANOVA, Welch, Kruskal-Wallis, Games-Howell y eta cuadrado | `input/base_salarios.rds` | tablas `05_*`, gráficos `g06`, `g09`, `a01` |
| `06_regresion.R` | Regresión con interacción y regresión múltiple | `input/base_salarios.rds` | tablas `06_*`, gráficos `g07`, `g10`, `a02` |
| `07_desigualdad_theil.R` | Gini, Theil y descomposición del Theil | `input/*.rds` | tablas `07_*`, gráficos `g08`, `g11` |

Las funciones propias están en `utils/`, una por archivo, y se cargan con `source()`. Los gráficos `a01` y `a02` son del anexo.

## Reproducibilidad

El script principal ejecuta los módulos de preparación, descriptivas, diagnóstico de faltantes y outliers, análisis inferencial, regresiones y desigualdad.

Los archivos intermedios se guardan en input/, mientras que las tablas y los gráficos generados se guardan en output/tablas/ y output/graficos/, respectivamente.

Para reproducir el análisis, alcanza con descargar el repositorio, abrir el proyecto de RStudio y ejecutar script/00_correr_todo.R.

## Fuente de datos

**Base utilizada:** Graduados universitarios del sistema Araucano (2016-2018).

**Fuente original:** [Datos Argentina - Graduados universitarios del sistema Araucano](https://datos.produccion.gob.ar/dataset/graduados-universitarios-del-sistema-araucano-2016-2018)

**Período de información sociolaboral:** 2019-2021.

**Unidad de observación:** persona-año. Cada graduado cuenta con tres registros, correspondientes a los años 2019, 2020 y 2021.

## Conclusiones principales

- **H1 (tipo de título), se sostiene.** Los salarios difieren entre tipos de título (ANOVA, Welch y Kruskal-Wallis, p < 0,001), pero el efecto es chico: el tipo de título explica el 3% de la variabilidad del log del salario (η² = 0,030).
- **H2 (gestión × título), se sostiene.** La brecha a favor de las privadas cambia según el título: de +7,5% en tecnicatura a +31,8% en pregrado (test de Wald robusto, p < 0,001). Al controlar por disciplina, región, título y género, la brecha agregada baja de 13,6% a 6,8%.
- **H3 (desigualdad), se sostiene.** La parte del Theil que se explica entre grupos es mayor para disciplina (8,9%) y región (6,0%) que para gestión (0,7%). En todas las características, más del 90% de la desigualdad ocurre dentro de los grupos.
- **Limitaciones:** solo se observa el empleo asalariado registrado en noviembre (el 41,6% de las filas no tiene salario), no hay horas trabajadas y los resultados no son causales.
