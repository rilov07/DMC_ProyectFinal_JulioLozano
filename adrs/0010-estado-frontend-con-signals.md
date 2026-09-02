# ADR 0010: Estado del frontend con Signals y servicios inyectables

## Estado

Aceptado

## Contexto

El Design.md describe vistas cuyo estado de interfaz no es trivial:

- **Pantalla 04 (bandeja de validación):** patrón de tres zonas — rail de filtros y colas, canvas
  central con la tabla, y panel de detalle — que deben mantenerse sincronizadas, más selección
  múltiple para acciones en lote.
- **Pantalla 05 (comparador de duplicados):** radio y ventana de tiempo ajustables desde la propia
  vista, con el mapa y la lista de candidatos reaccionando al cambio.
- **Pantalla 02 (formulario de reporte):** tres pasos con indicador de progreso y un borrador que
  debe sobrevivir a la pérdida de conexión (caso borde E5).

La [ADR-0001](0001-topologia-spa-angular-mas-api-propia.md) dejó claro que el frontend no contiene
reglas de negocio, así que el estado que gestiona es de interfaz y de datos en caché, no de
dominio. El equipo es de una persona.

## Decisión

El estado del frontend se maneja con **Signals de Angular dentro de servicios inyectables**, uno
por feature (bandeja de validación, comparador de duplicados, borrador de reporte, mis
asignaciones, dashboard). Cada servicio expone signals de solo lectura hacia los componentes y
métodos que los actualizan; los valores derivados se calculan con `computed`.

No se adopta ninguna librería de gestión de estado externa. El estado del servidor se obtiene por
el cliente generado en la [ADR-0009](0009-contrato-rest-openapi.md) y se deposita en esos signals.

## Alternativas consideradas

- **NgRx (patrón Redux)** — Habría dado un estado global predecible, trazable con devtools y con una
  convención impuesta que sobrevive al paso del tiempo y de los desarrolladores. Se descartó por
  desproporción: exige acciones, reducers, efectos y selectores por cada caso de uso, y el estado
  real de este producto es mayormente estado de servidor consultado y algo de estado de vista
  local. El costo en volumen de código no lo paga un equipo de una persona con plazo de curso.
- **RxJS puro con `BehaviorSubject` en servicios** — El patrón clásico de Angular, sin dependencias
  nuevas y perfectamente capaz. Se descartó porque Signals cubre el mismo caso con menos código, sin
  el riesgo de suscripciones no liberadas, y porque es la dirección hacia la que el propio framework
  se está moviendo.

## Consecuencias

- Sin dependencias externas de estado y sin boilerplate: cada feature tiene un servicio que se lee
  de arriba abajo, lo que reduce el tiempo de implementación de las siete vistas del Design.md.
- Los valores derivados que las pantallas necesitan —el conteo de seleccionados en la bandeja, los
  candidatos filtrados por radio y ventana en el comparador, el paso válido del formulario— se
  expresan como `computed` y se recalculan solos, que es exactamente la forma de esas vistas.
- La detección de cambios se vuelve más eficiente y predecible que con el modelo clásico,
  relevante para las vistas densas en datos que describe el sistema visual.
- **Costo:** no hay convención impuesta ni herramientas de inspección del estado. La consistencia
  entre features depende de la disciplina del autor, y depurar un estado inconsistente es
  observarlo a mano, sin time-travel.
- **Costo:** al no haber una capa de caché de datos de servidor (que NgRx u otras librerías dan de
  fábrica), cada servicio decide por su cuenta cuándo refrescar y cuándo reutilizar lo que ya tiene.
  Eso interactúa directamente con el polling de la [ADR-0011](0011-frescura-por-polling.md) y hay
  que resolverlo de forma consistente para no duplicar peticiones.
