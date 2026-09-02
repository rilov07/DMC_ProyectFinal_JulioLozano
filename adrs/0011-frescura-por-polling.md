# ADR 0011: Frescura de dashboard y notificaciones mediante polling del cliente

## Estado

Aceptado

## Contexto

El PRD fija un criterio de éxito medible: "El dashboard refleja el conteo de incidencias por estado,
tipo y zona con una **latencia de actualización menor a 5 minutos** respecto al último cambio
registrado". También exige "notificaciones internas ante cambios relevantes (nueva asignación,
cambio de estado)", y excluye explícitamente del alcance las notificaciones públicas masivas a la
ciudadanía.

El Design.md refuerza el criterio haciéndolo visible: la pantalla 10 lleva una "marca de
actualización visible para hacer legible el criterio de latencia <5 min", y la pantalla 09 es de
notificaciones internas y escalamiento.

Restricción heredada: entre el scheduler embebido de la [ADR-0002](0002-stack-nestjs-typescript.md)
y el almacenamiento en disco local de la [ADR-0008](0008-evidencia-en-sistema-de-archivos.md), el
despliegue está comprometido con **una sola instancia de la API**. Cualquier mecanismo que consuma
conexiones persistentes compite por los mismos workers que atienden las consultas y la descarga de
imágenes.

## Decisión

El frontend **consulta periódicamente** (polling) los endpoints correspondientes:

- **Dashboard:** refresco cada ~60 segundos, con la marca de última actualización que el Design.md
  pide, mostrada a partir de la marca temporal que devuelve la propia respuesta.
- **Bandeja de notificaciones internas:** consulta cada ~30 segundos del contador de no leídas.
- **Bandeja de validación y mis asignaciones:** refresco al enfocar la vista y bajo acción explícita
  del usuario; no en un temporizador continuo.

El polling se detiene cuando la pestaña no está visible y se reanuda al volver, para no gastar
peticiones ni batería en móvil. Los intervalos son configurables, no constantes incrustadas en el
código.

## Alternativas consideradas

- **Server-Sent Events (SSE)** — Técnicamente la forma más ajustada al problema: empuje del servidor
  al cliente, unidireccional, sobre HTTP simple, sin el peso de un protocolo aparte. Se descartó
  porque cada cliente conectado mantendría una conexión abierta ocupando un worker de la única
  instancia de la API, que además sirve las imágenes de evidencia; y porque el beneficio —bajar la
  latencia de 60 segundos a casi cero— no compra nada frente a un requisito que pide menos de 5
  minutos.
- **WebSockets** — Latencia mínima y canal bidireccional. Se descartó porque ninguna función de este
  producto necesita que el cliente empuje datos por un canal persistente: todas las escrituras son
  acciones puntuales que encajan en una petición REST. Sería infraestructura, manejo de
  reconexión y estado de conexión pagados sin beneficio.

## Consecuencias

- El criterio de los 5 minutos del PRD se cumple con un margen de cinco veces, lo que deja espacio
  para que el intervalo se relaje si la carga lo exigiera, sin incumplir el requisito.
- El servidor permanece sin conexiones persistentes: no hay estado de conexión que gestionar, ni
  reconexión, ni riesgo de agotar los workers de la instancia única con clientes inactivos.
- La "marca de actualización visible" de la pantalla 10 deja de ser un adorno y pasa a ser
  información honesta: el usuario ve exactamente de cuándo son los datos que está mirando, que es
  justo lo que el Design.md buscaba comunicar.
- **Costo:** el sistema no es de tiempo real. Un validador y una cuadrilla mirando la misma
  incidencia pueden ver estados distintos hasta por un minuto, y una notificación de escalamiento
  puede tardar hasta 30 segundos en aparecer. Aceptable aquí, pero es una limitación real del
  producto, no un detalle de implementación.
- **Costo:** se generan peticiones aunque no haya cambios. Con pocos usuarios internos simultáneos
  el volumen es despreciable, pero crece linealmente con las sesiones abiertas; si el número de
  usuarios internos creciera mucho, esta decisión debería revisarse.
- **Costo:** los endpoints de agregación del dashboard se ejecutan cada minuto por cada supervisor
  conectado, así que deben ser consultas baratas. Si el volumen de incidencias las vuelve lentas,
  habrá que precalcular los agregados en vez de subir el intervalo.
