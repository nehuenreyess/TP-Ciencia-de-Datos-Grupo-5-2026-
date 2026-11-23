# Trabajo Práctico Final — Ciencia de Datos para Economía y Negocios

**Grupo 5 · Facultad de Ciencias Económicas · Universidad de Buenos Aires**

## Tema
Diferencias salariales entre graduados universitarios e inserción laboral.

## Objetivo
Analizar cómo se relacionan las características educativas y sociodemográficas de las personas graduadas con sus salarios observados, y estudiar si la diferencia salarial entre egresados de instituciones de gestión privada y estatal varía según el tipo de título.

El análisis es observacional. Los resultados describen asociaciones y diferencias entre grupos; no deben interpretarse como efectos causales.

## Estructura del repositorio

```text
.
├── auxiliar/                 # Insumos auxiliares
├── input/               # Archivos de entrada preparados
├── output/
│   ├── tablas/           # Tablas generadas
│   └── graficos/         # Gráficos generados
├── raw/            # Datos originales y diccionario
├── script/              # Scripts de análisis
├── utils/               # Funciones auxiliares propias
└── README.md
```

## Cómo ejecutar

1. Clonar o descargar este repositorio.
2. Abrir el proyecto desde RStudio.
3. Instalar, una sola vez, las dependencias necesarias:

```r
install.packages(c(
  "tidyverse", "readxl", "scales", "ggtext",
  "showtext", "rstatix", "lmtest", "sandwich"
))
```

4. Colocar los archivos de datos requeridos en `raw/` (ver la sección siguiente).
5. Ejecutar desde la raíz del proyecto:

```r
source("script/00_correr_todo.R")
```

Los scripts utilizan rutas relativas al directorio del proyecto. No es necesario configurar `setwd()`.

## Datos

La base de microdatos y su diccionario deben estar disponibles localmente en:

- `raw/base_araucano.csv.gz`
- `raw/diccionario.xlsx`

Por el tamaño del archivo de microdatos, puede que no esté versionado directamente en GitHub. En ese caso, descargar la base desde la fuente oficial indicada en la documentación del trabajo y guardarla con el nombre y la ruta anteriores. No modificar la base original. El diccionario debe conservar la hoja `cod_disciplina`.

**Importante:** el análisis no es reproducible desde cero hasta que ambos archivos estén presentes en `raw/`.

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

El script principal ejecuta los módulos de preparación, descriptivas, diagnóstico de faltantes y outliers, análisis inferencial, regresiones y desigualdad. Los resultados generados se guardan en las carpetas correspondientes de `output/`.

