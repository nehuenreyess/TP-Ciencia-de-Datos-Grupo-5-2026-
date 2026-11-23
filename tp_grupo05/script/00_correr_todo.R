# 00 - Corre todos los scripts en orden
# Abrir el proyecto tp_grupo05.Rproj antes de correr este script, así la
# carpeta de trabajo es tp_grupo05 y las rutas relativas funcionan.

scripts <- c(
  "script/01_preparacion_base.R",
  "script/02_descriptivas_iniciales.R",
  "script/03_faltantes_outliers.R",
  "script/04_descriptivas_post_limpieza.R",
  "script/05_anova.R",
  "script/06_regresion.R",
  "script/07_desigualdad_theil.R"
)

for (s in scripts) {
  message("Corriendo ", s)
  source(s, encoding = "UTF-8")
}
