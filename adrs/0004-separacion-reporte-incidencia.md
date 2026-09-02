# ADR 0004: Separar `Reporte` (testimonio ciudadano) de `Incidencia` (unidad de trabajo)

## Estado

Aceptado

## Contexto

El PRD establece en sus casos borde que cuando dos o más ciudadanos reportan la misma incidencia
casi simultáneamente "el sistema debe agruparlos como posibles duplicados y **no crear responsables
asignados duplicados**". El Design.md lo refuerza en la pantalla 05 (comparador / agrupación de
duplicados): "Al agrupar, un solo responsable".

Eso obliga a definir qué objeto exactamente se asigna, cambia de estado y acumula historial. Si el
objeto asignable es el mismo que el ciudadano envía, agrupar N reportes implica elegir uno como
"principal" y arrastrar su estado, su asignación y su historial.

Al mismo tiempo, la pantalla 03 del Design.md le promete al ciudadano un folio citable y una línea
de estados que muestra "qué sigue", de modo que el reportante debe poder seguir el avance de lo que
reportó.

## Decisión

El modelo separa dos entidades:

- **`Reporte`** — lo que envía un ciudadano: tipo de incidencia, descripción, coordenadas,
  evidencia fotográfica, fecha-hora y contacto opcional. Tiene folio propio y citable. Es
  **inmutable** una vez enviado: nadie edita el testimonio de un ciudadano.
- **`Incidencia`** — la unidad de trabajo del equipo operativo. Es lo único que tiene estado
  (`reportado → validado → asignado → en proceso → resuelto`, o `descartado`), responsable,
  prioridad, plazo e historial de cambios.

La relación es de uno a muchos: una `Incidencia` agrupa 1..N `Reporte`. Al validar un reporte se
crea su incidencia; agrupar duplicados es reapuntar reportes adicionales a una incidencia ya
existente, sin tocar el estado de nadie. El seguimiento ciudadano de la pantalla 03 se resuelve
mostrando, para el folio del reporte, el estado de la incidencia a la que quedó asociado.

## Alternativas consideradas

- **Una sola entidad `Reporte` con autorreferencia `duplicado_de`** — Era viable y notablemente más
  simple: una tabla, sin joins adicionales, y el duplicado se marca como `descartado` con causal
  "duplicado" apuntando al reporte principal. Se descartó porque obliga al reporte principal a
  cumplir dos papeles incompatibles: es a la vez el testimonio de un ciudadano concreto y la unidad
  de trabajo del equipo. Consecuencias prácticas de esa doble función: el trabajo "pertenece" al
  primero que reportó aunque su foto o su ubicación sean las peores del grupo; cambiar de reporte
  titular exige mover estado, asignación e historial completos; y el historial de trabajo del
  equipo queda mezclado con el registro de un envío ciudadano que debería ser inmutable.
- **Entidad `Reporte` más una tabla `Grupo` sin estado propio** — Un punto intermedio: los grupos
  agrupan reportes pero el estado sigue en el reporte principal. Se descartó porque hereda el mismo
  problema (el estado vive en un testimonio ciudadano) sin ganar la simplicidad de la opción
  anterior.

## Consecuencias

- La regla "un solo responsable por incidencia agrupada" del Design.md sale directamente del
  modelo: la asignación cuelga de `Incidencia`, así que estructuralmente no pueden existir
  responsables duplicados para el mismo problema físico.
- Agrupar y desagrupar reportes es una operación barata y reversible: se cambia la clave foránea de
  un reporte, sin efectos sobre estados ni historial. Esto importa porque el propio PRD advierte
  que la detección por proximidad puede dar falsos positivos, y el Design.md permite ajustar radio
  y ventana desde la vista — es decir, se espera equivocarse y corregir.
- El testimonio ciudadano queda inmutable y auditable, y el historial de `Incidencia` contiene solo
  acciones del equipo operativo, que es exactamente lo que la auditoría del PRD pide registrar.
- **Costo:** una tabla y un join más en casi toda consulta operativa, y dos folios conceptuales en
  el sistema (el del reporte, que el ciudadano cita, y el de la incidencia, que el equipo usa). La
  interfaz debe evitar confundirlos.
- **Costo:** aparece un estado transitorio que el modelo de una sola entidad no tenía — el reporte
  recién enviado que aún no pertenece a ninguna incidencia. La bandeja de validación se define
  entonces como "reportes sin incidencia asociada", y la pantalla 03 debe saber qué mostrarle al
  ciudadano mientras ese vínculo no existe.
