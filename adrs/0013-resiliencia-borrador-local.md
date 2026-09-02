# ADR 0013: Resiliencia del reporte — borrador local con reintento manual

## Estado

Aceptado

## Contexto

Dos casos borde del PRD apuntan al mismo momento frágil, el ciudadano llenando el formulario en la
calle:

- "Pérdida de conexión durante el llenado del formulario: no debe perderse la información ya
  ingresada (guardado local temporal o confirmación antes de salir)."
- "Fotografía no se puede subir (conexión débil, formato no soportado): el reporte debe poder
  guardarse igual, marcando la evidencia como pendiente."

El Design.md los diseñó como E5 ("Sin conexión: borrador local, formulario atenuado, descartar o
reintentar") y E2 ("Foto sin subir: evidencia etiquetada `PENDIENTE`, reporte guardado igual"), y
en la pantalla 02 estableció que "solo tipo y ubicación son obligatorios; la foto nunca bloquea el
envío".

El "No alcance" del PRD excluye la aplicación móvil nativa, pero no se pronuncia sobre una PWA.

## Decisión

**El borrador del reporte se persiste en el almacenamiento local del navegador** después de cada
paso del formulario de tres pasos. Al perder conexión, el formulario se atenúa y se ofrecen dos
acciones —**reintentar** o **descartar**— tal como dibuja E5. Al volver a abrir la aplicación con un
borrador pendiente, se ofrece retomarlo.

El **envío del reporte y la subida de fotografías son operaciones separadas**: el reporte se crea
con tipo y ubicación (los únicos campos obligatorios) y responde con folio; las fotografías se
suben después contra ese folio. Una foto que no llega a subirse deja su registro de evidencia en
estado `PENDIENTE`, sin bloquear ni invalidar el reporte, que es exactamente lo que E2 exige.

La creación del reporte es **idempotente respecto de un identificador de borrador** generado en el
cliente, de modo que un reintento tras una respuesta perdida no produzca dos reportes del mismo
envío.

## Alternativas consideradas

- **PWA con Service Worker y cola de sincronización en segundo plano** — Era la mejor experiencia
  posible para el usuario real de este producto: alguien reportando desde la calle, con señal
  intermitente; el reporte se enviaría solo al recuperar cobertura, aunque la pestaña ya estuviera
  cerrada. Se descartó por su costo de complejidad —ciclo de vida del Service Worker, subida
  diferida de binarios, depuración difícil— y porque promete un funcionamiento offline que el PRD
  nunca pidió: el requisito es no perder lo escrito, no enviar sin conexión.
- **Solo confirmación antes de salir, sin persistencia** — Es literalmente una de las dos opciones
  que el PRD acepta ("guardado local temporal **o** confirmación antes de salir") y la de menor
  esfuerzo. Se descartó porque no cumple E5 del Design.md, que ya diseñó el borrador local, y
  porque un diálogo de confirmación no protege ante el cierre accidental de la pestaña, el agotado
  de batería o el cambio de aplicación en móvil — que son los escenarios reales de la calle.

## Consecuencias

- El avance del ciudadano sobrevive a la pérdida de conexión y al cierre de la pestaña, cumpliendo
  el caso borde del PRD por la vía fuerte de las dos que ofrecía.
- Separar la creación del reporte de la subida de fotos hace que el criterio de éxito de los 2
  minutos sea alcanzable incluso con conexión mala: el reporte queda registrado con coordenadas
  válidas y el peso de la evidencia se resuelve después.
- La idempotencia por identificador de borrador evita el duplicado técnico —el mismo envío contado
  dos veces— que es un problema distinto del duplicado real que trata la
  [ADR-0012](0012-deteccion-de-duplicados.md) y que la detección geográfica no distinguiría bien.
- **Costo:** si el ciudadano nunca vuelve a abrir la aplicación, el borrador nunca se envía. El
  sistema pierde ese reporte de forma silenciosa, y es justo el caso que la PWA habría cubierto.
- **Costo:** el borrador vive en el navegador con las fotografías seleccionadas, lo que puede chocar
  con los límites de almacenamiento local en móvil. Hay que limitar el número y el tamaño de las
  imágenes conservadas en borrador, y degradar con claridad si no caben.
- **Costo:** las evidencias en estado `PENDIENTE` son deuda que alguien debe cerrar. Sin una vista
  o un proceso que las liste, se acumulan invisibles; el diseño debe exponerlas como señal en la
  bandeja de validación.
