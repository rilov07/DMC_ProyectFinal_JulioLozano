# ADR 0006: Zona como catálogo de polígonos, derivada por PostGIS al crear el reporte

## Estado

Aceptado

## Contexto

El PRD exige que "el dashboard refleje el conteo de incidencias por estado, tipo y **zona**" y que
muestre distribución geográfica o mapa de calor. El Design.md añade dos usos más de la geografía
administrativa: la fila de metadatos de la tarjeta de incidencia muestra **zona** como dato de
sistema (`label-mono`), y el caso borde E4 dibuja un **polígono de ámbito geográfico** — un reporte
cuyas coordenadas caen fuera de él se envía igual, pero llega marcado como `FUERA ÁMB.` a la
bandeja de validación.

El PRD deja abierto el alcance exacto ("una ciudad o provincia definida") y advierte que si se
requiere escalar a múltiples localidades el modelo de datos deberá revisarse.

## Decisión

Existe una entidad **`Zona`** con nombre y un polígono `geography(Polygon, 4326)` en la base de
datos. La zona de un reporte **no la elige nadie**: se deriva de sus coordenadas al momento de
crearlo, con `ST_Within` contra el catálogo de zonas, y se persiste en el reporte como valor
resuelto.

El **ámbito geográfico** del despliegue es la unión de las zonas activas. Un reporte cuyas
coordenadas no caen dentro de ninguna zona se acepta y se persiste con zona nula y una señal
`FUERA_AMBITO`, tal como exige E4.

## Alternativas consideradas

- **Zona como campo de texto elegido por el reportante** — Trivial de implementar y sin dependencia
  de datos geográficos externos. Se descartó porque produce un dato no verificable contra las
  coordenadas del propio reporte: un ciudadano que elige mal el distrito, o que no lo conoce,
  ensucia directamente el conteo por zona del dashboard, que es un criterio de éxito del PRD.
  Además añade un campo al formulario, en tensión con el objetivo de reportar en menos de 2
  minutos.
- **Sin entidad zona, agregando por rejilla geográfica al vuelo** — Suficiente y elegante para el
  mapa de calor, sin necesidad de cargar polígonos administrativos. Se descartó porque el PRD pide
  explícitamente conteo *por zona*, y una rejilla puede pintar densidad pero no puede responder
  "cuántas incidencias hay en el distrito X", que es la pregunta que un supervisor municipal
  necesita responder.

## Consecuencias

- La zona es siempre coherente con las coordenadas del reporte, porque se calcula a partir de
  ellas. El conteo por zona del dashboard es confiable por construcción, no por disciplina del
  reportante.
- El formulario ciudadano no gana ningún campo, lo que protege el criterio de los 2 minutos.
- El ámbito geográfico vive como dato y no como constante en el código: ajustar el ámbito o añadir
  un distrito es cargar o modificar un polígono, sin despliegue. Esto responde parcialmente al
  pendiente #1 del Design.md y deja abierta la puerta al escenario multi-zona que el PRD advierte,
  sin comprometerse hoy a soportarlo.
- Persistir la zona resuelta en el reporte (en lugar de recalcularla en cada consulta) mantiene
  barato el dashboard, que debe reflejar cambios con menos de 5 minutos de latencia.
- **Costo:** hay que conseguir y cargar los polígonos reales de los distritos del ámbito elegido, lo
  que es una dependencia externa de datos (fuente oficial, formato, calidad de los límites) antes
  de que el dashboard sirva de algo. Es trabajo previo que las otras dos alternativas no exigían.
- **Costo:** al persistir la zona resuelta, redibujar los límites de una zona no reetiqueta los
  reportes antiguos automáticamente. Un cambio de límites requiere un proceso de recálculo
  explícito.
- **Costo:** la derivación de zona ocurre en la ruta crítica de creación del reporte, así que esa
  consulta espacial debe estar indexada y no puede bloquear el envío; si falla, el reporte se
  guarda con zona nula y se resuelve después, antes que perder el reporte.
