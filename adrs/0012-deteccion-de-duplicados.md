# ADR 0012: Detección de duplicados con auto-agrupación reversible bajo umbral estricto

## Estado

Aceptado

## Contexto

El PRD incluye en el alcance la "detección de incidencias similares o duplicadas (por cercanía
geográfica y tipo, dentro de una ventana de tiempo)" y la convierte en criterio de éxito: el
validador debe poder identificar duplicados "mismo tipo, radio configurable de cercanía, ventana de
tiempo configurable" antes de aprobarlos. El caso borde correspondiente exige además que reportes
casi simultáneos de la misma incidencia "no creen responsables asignados duplicados".

El mismo PRD marca el riesgo: la detección por proximidad "puede generar falsos positivos (agrupar
incidencias distintas cercanas) o falsos negativos", y "el criterio exacto de *similar* debe
afinarse con el equipo funcional".

El Design.md tomó dos posiciones previas: en el caso borde E3, al ciudadano se le muestran los
reportes cercanos del mismo tipo y "su respuesta es una señal, no una decisión"; y la pantalla 05
permite ajustar radio y ventana desde la propia vista, explícitamente "por el riesgo de falsos
positivos".

## Decisión

La detección opera en **tres momentos**, sobre `ST_DWithin` contra la columna `geography` de la
[ADR-0003](0003-persistencia-postgresql-postgis.md), filtrando siempre por tipo de incidencia y
ventana de tiempo:

1. **Al crear el reporte (cliente):** se le muestran al ciudadano los reportes cercanos del mismo
   tipo. Su respuesta se persiste como señal, nunca como decisión (E3).
2. **Al ingresar el reporte (servidor), auto-agrupación bajo umbral estricto:** si existe una
   incidencia abierta del mismo tipo dentro del umbral estricto configurado, el reporte se adjunta
   automáticamente a ella en lugar de generar una nueva entrada en la bandeja.
3. **Bajo demanda en el comparador (pantalla 05):** el validador recalcula candidatos con radio y
   ventana ajustables desde la vista.

La auto-agrupación es **reversible y visible**, que es la condición bajo la cual se adopta:

- La incidencia que recibió un reporte por auto-agrupación queda marcada con la señal
  `AGRUPADO AUTO` en la bandeja de validación hasta que un validador la confirme explícitamente.
- **Desagrupar es una sola acción** que devuelve el reporte a la bandeja como pendiente, sin afectar
  el estado ni el historial de la incidencia de la que salió — algo que el modelo de la
  [ADR-0004](0004-separacion-reporte-incidencia.md) hace barato por construcción.
- Toda auto-agrupación y toda desagrupación escriben entrada en el historial de la incidencia,
  indicando que el actor fue el sistema o el validador.

Los umbrales (radio estricto, ventana estricta, radio y ventana de sugerencia) son **configuración
persistida con valor por defecto**, no constantes en el código, tal como el PRD exige al llamarlos
"configurables".

## Alternativas consideradas

- **Sugerencia siempre, decisión siempre humana** — Era la opción alineada con lo que el Design.md
  ya insinuaba: el sistema calcula candidatos pero agrupar es siempre un acto del validador. Se
  descartó por decisión del usuario, priorizando que los casos evidentes —varios ciudadanos
  reportando el mismo bache en minutos— no consuman tiempo del validador uno por uno.
- **Auto-agrupación en firme, sin marca de revisión** — Habría dado el máximo ahorro de trabajo: el
  reporte duplicado se adjunta y desaparece de la bandeja. Se descartó porque vuelve invisible el
  falso positivo: dos incidencias distintas fusionadas quedarían sin que nadie pueda detectarlo, y
  una de ellas se cerraría bajo el estado de la otra sin ser atendida.
- **Umbral doble sin marca posterior** (uno muy estrecho que agrupa en firme, uno amplio que
  sugiere) — Reducía el falso positivo estrechando el criterio. Se descartó porque un criterio más
  estrecho reduce la probabilidad del error pero no lo hace detectable, y el PRD advierte que el
  criterio correcto aún no está afinado con el equipo funcional.

## Consecuencias

- Los duplicados evidentes dejan de consumir tiempo del validador, que es el cuello de botella
  humano del flujo, sin que el sistema pierda la capacidad de equivocarse de forma visible.
- La condición de reversibilidad convierte el falso positivo en un incidente recuperable en vez de
  un fallo silencioso: la señal `AGRUPADO AUTO` obliga a que un humano pase por ahí, y desagrupar
  no destruye nada. La pantalla 05 conserva su razón de ser, cambiando de "agrupar" a "revisar lo
  agrupado".
- Que los umbrales sean configuración y no código permite exactamente lo que el PRD pide: afinar el
  criterio con el equipo funcional en operación, sin desplegar.
- El historial registra al sistema como actor de la agrupación, así que la auditoría del PRD sigue
  siendo completa aunque la acción no la haya tomado una persona.
- **Costo:** el sistema aplica un criterio de similitud que el propio PRD reconoce como no afinado.
  Hasta que los umbrales se calibren con el equipo operativo, deben arrancar deliberadamente
  conservadores (radio pequeño, ventana corta), aceptando falsos negativos —que solo significan
  trabajo manual— antes que falsos positivos.
- **Costo:** aparece un estado de bandeja que no existía en el Design.md (`AGRUPADO AUTO` pendiente
  de confirmación), lo que añade una columna de señal y una acción de desagrupar a la pantalla 04 y
  cambia el propósito de la 05. Hay que reflejarlo en el diseño antes de alta fidelidad.
- **Costo:** la consulta espacial se ejecuta en la ruta crítica de creación del reporte, junto a la
  derivación de zona de la [ADR-0006](0006-zona-como-catalogo-de-poligonos.md). Ambas deben estar
  indexadas y ninguna puede bloquear el envío: si fallan, el reporte se guarda igual y queda como
  pendiente en la bandeja.
