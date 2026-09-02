# ADR 0005: Reporte ciudadano anónimo con contacto opcional

## Estado

Aceptado

## Contexto

El PRD declara explícitamente que "no se define aquí el mecanismo de autenticación" y el Design.md
lo deja como pendiente #5 antes de alta fidelidad: "Confirmar si el ciudadano se autentica o
reporta de forma anónima; hoy 06 asume anónimo".

Dos exigencias del PRD tiran en direcciones opuestas:

- Criterio de éxito: "Un reportante puede crear un reporte georreferenciado con al menos una
  fotografía en **menos de 2 minutos** desde un dispositivo móvil".
- Caso borde: "Un mismo usuario reporta incidencias falsas repetidamente: se requiere capacidad de
  marcar reportes como inválidos **sin bloquear la creación de nuevos reportes legítimos por otros
  usuarios**".

El segundo caso borde, leído con atención, no pide bloquear al reincidente: pide poder invalidar
sus reportes sin que eso afecte a terceros. Esa es una exigencia más débil que la de identificar
personas.

## Decisión

El ciudadano **reporta sin cuenta**. El formulario no exige autenticación en ningún paso. Se ofrece
un campo **opcional** de contacto (correo o teléfono) para recibir el avance del reporte, y el
folio del reporte funciona como hilo de seguimiento para quien no lo deja.

Los roles internos (validador, responsable/cuadrilla, supervisor) sí se autentican; esa es una
decisión distinta, cubierta por [ADR-0007](0007-autenticacion-y-autorizacion.md).

Para el reincidente, el sistema no identifica personas: registra en cada reporte una huella técnica
del origen (dirección IP y marca temporal) que permite al validador ver una ráfaga de reportes del
mismo origen y descartarlos en lote, sin bloquear la creación de reportes nuevos por parte de
nadie.

## Alternativas consideradas

- **Anónimo puro, sin contacto** — La fricción absolutamente mínima, alineada al máximo con el
  criterio de los 2 minutos. Se descartó porque deja al ciudadano sin ninguna vía de aviso cuando
  su incidencia se resuelve, y el Design.md ya diseñó una pantalla de seguimiento (03) que sugiere
  una relación continuada con el reportante, no un envío a ciegas.
- **Registro obligatorio del ciudadano** — Era la única opción que hace la reincidencia realmente
  medible y que permitiría, más adelante, reputación del reportante. Se descartó porque contradice
  frontalmente el criterio de éxito de los 2 minutos: crear una cuenta, verificarla e iniciar
  sesión desde la calle es incompatible con ese objetivo, y suprimiría el volumen de reportes, que
  es el insumo del que depende todo el producto.

## Consecuencias

- Se preserva el criterio de éxito de los 2 minutos, que es el que sostiene el volumen de reportes
  y, por tanto, el valor de todo el sistema.
- Queda resuelto el pendiente #5 del Design.md, y las pantallas 01–03 pueden llevarse a alta
  fidelidad sin un flujo de registro.
- El campo de contacto es opcional, así que el ciudadano que quiere seguimiento lo obtiene sin
  imponérselo al que solo quiere reportar y seguir su camino.
- **Costo:** el contacto opcional es dato personal. Obliga a tratarlo como tal (no exponerlo en
  listados, no incluirlo en exportaciones del dashboard, y definir por cuánto tiempo se conserva),
  lo que añade una responsabilidad que el anonimato puro no tenía.
- **Costo:** la detección del reportante reincidente queda débil. La huella por IP agrupa a usuarios
  legítimos detrás de una misma red móvil o corporativa y se evade trivialmente cambiando de red,
  así que sirve como señal para el validador, nunca como criterio automático de rechazo. Si el
  abuso resultara ser un problema real en operación, habría que reconsiderar esta decisión.
- **Costo:** sin identidad del reportante, el sistema no puede notificar la resolución a quien no
  dejó contacto; para ese caso, la consulta por folio de la pantalla 03 es el único canal.
