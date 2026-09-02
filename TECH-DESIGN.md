# Technical Design Document: GeoReport Vial

**Tipo de proyecto:** Greenfield — no existe código previo; todas las decisiones se tomaron en esta
sesión.
**Design.md disponible:** Sí — `Desing.md`, sistema visual "Industry", 10 pantallas inventariadas,
modelo de estados y decisiones de flujo. Se usó como fuente primaria del modelo de datos junto al
PRD.

## Resumen

GeoReport Vial es una plataforma web responsiva para registrar, validar, asignar y hacer seguimiento
de incidencias de infraestructura vial local (baches, derrumbes, huaicos, semáforos averiados,
puentes bloqueados y el resto del catálogo del PRD). Resuelve el problema que el PRD identifica: hoy
los reportes se dispersan entre canales informales, no se georreferencian, se duplican y no dejan
trazabilidad de quién los atiende. El sistema se construye como una SPA en Angular con mapas
Leaflet/OpenStreetMap contra una API propia en NestJS respaldada por PostgreSQL con PostGIS, donde
vive toda la lógica de dominio: validación, detección de duplicados por proximidad, máquina de
estados con historial inmutable y escalamiento por plazo vencido.

## Arquitectura de componentes

Dos componentes desplegables ([ADR-0001](adrs/0001-topologia-spa-angular-mas-api-propia.md)), ambos
nuevos:

```
   Ciudadano (móvil, sin cuenta)          Validador · Cuadrilla · Supervisor (autenticados)
              │                                          │
              └──────────────┬───────────────────────────┘
                             ▼
                  ┌────────────────────────┐
                  │   georeport-web        │  SPA Angular + Leaflet/OSM
                  │   (Signals, sin        │  · Dibuja mapa, marcadores, radio,
                  │    reglas de negocio)  │    polígono de ámbito, mapa de calor
                  └───────────┬────────────┘  · Borrador local del reporte
                              │               · Polling de dashboard y notificaciones
                    REST/JSON │ (contrato OpenAPI, cookie httpOnly)
                              ▼
                  ┌────────────────────────┐
                  │   georeport-api        │  NestJS / TypeScript
                  │   (toda la lógica de   │  · Auth y autorización por rol
                  │    dominio)            │  · Validación y máquina de estados
                  │                        │  · Duplicados (ST_DWithin) y zona (ST_Within)
                  │  @Scheduled: job de    │  · Agregados del dashboard
                  │  escalamiento          │  · Evidencia en disco local
                  └──────┬──────────┬──────┘
                         │          │
              ┌──────────▼───┐  ┌───▼──────────────┐
              │ PostgreSQL   │  │ Volumen de disco │
              │ + PostGIS    │  │ (evidencia)      │
              └──────────────┘  └──────────────────┘
```

**Responsabilidades.** `georeport-web` es un cliente sin autoridad: cualquier regla que aplique
(deshabilitar un botón, exigir foto de cierre) es comodidad de interfaz que la API revalida.
`georeport-api` es dueña del contrato, del dominio y de la autorización.

**Restricción de despliegue heredada de las decisiones.** El scheduler embebido
([ADR-0002](adrs/0002-stack-nestjs-typescript.md)) y la evidencia en disco local
([ADR-0008](adrs/0008-evidencia-en-sistema-de-archivos.md)) comprometen a `georeport-api` a **una
sola instancia** con volumen persistente. Escalar horizontalmente exige revisar ambas ADR.

## Decisiones de arquitectura

| # | Decisión | Estado |
|---|---|---|
| [ADR-0001](adrs/0001-topologia-spa-angular-mas-api-propia.md) | Topología de dos componentes — SPA Angular + API propia | Aceptado |
| [ADR-0002](adrs/0002-stack-nestjs-typescript.md) | Stack de `georeport-api` — NestJS sobre Node.js y TypeScript | Aceptado |
| [ADR-0003](adrs/0003-persistencia-postgresql-postgis.md) | Persistencia en PostgreSQL con la extensión PostGIS | Aceptado |
| [ADR-0004](adrs/0004-separacion-reporte-incidencia.md) | Separar `Reporte` (testimonio) de `Incidencia` (unidad de trabajo) | Aceptado |
| [ADR-0005](adrs/0005-reporte-anonimo-con-contacto-opcional.md) | Reporte ciudadano anónimo con contacto opcional | Aceptado |
| [ADR-0006](adrs/0006-zona-como-catalogo-de-poligonos.md) | Zona como catálogo de polígonos, derivada por PostGIS | Aceptado |
| [ADR-0007](adrs/0007-autenticacion-y-autorizacion.md) | Autenticación de roles internos con JWT en cookie `httpOnly` | Aceptado |
| [ADR-0008](adrs/0008-evidencia-en-sistema-de-archivos.md) | Evidencia fotográfica en el sistema de archivos del servidor | Aceptado |
| [ADR-0009](adrs/0009-contrato-rest-openapi.md) | Contrato REST documentado con OpenAPI y cliente Angular generado | Aceptado |
| [ADR-0010](adrs/0010-estado-frontend-con-signals.md) | Estado del frontend con Signals y servicios inyectables | Aceptado |
| [ADR-0011](adrs/0011-frescura-por-polling.md) | Frescura de dashboard y notificaciones mediante polling | Aceptado |
| [ADR-0012](adrs/0012-deteccion-de-duplicados.md) | Detección de duplicados con auto-agrupación reversible | Aceptado |
| [ADR-0013](adrs/0013-resiliencia-borrador-local.md) | Resiliencia del reporte — borrador local con reintento manual | Aceptado |

## Modelo de datos

Entidades derivadas del PRD y de lo que las pantallas del Design.md obligan a mostrar.

### `Zona`
`id`, `nombre`, `poligono geography(Polygon,4326)` (índice GiST), `activa`.
El ámbito geográfico del despliegue es la unión de las zonas activas
([ADR-0006](adrs/0006-zona-como-catalogo-de-poligonos.md)).

### `TipoIncidencia`
`id`, `nombre`, `activo`, `plazo_por_defecto_horas`.
Catálogo cerrado del PRD: pistas/carreteras en mal estado, baches, accidentes que interrumpen el
tránsito, huaicos, derrumbes, inundaciones, señalización, semáforos averiados, guardavías, drenaje,
túneles, puentes. El plazo por tipo sostiene el escalamiento (pendiente #4 del Design.md, ver
riesgos).

### `Reporte` — testimonio ciudadano, inmutable
`id`, `folio` (citable, pantalla 03), `tipo_incidencia_id`, `descripcion`,
`ubicacion geography(Point,4326)` (índice GiST), `zona_id` (derivada, nullable),
`fuera_de_ambito` (bool, señal `FUERA ÁMB.` de E4), `contacto_opcional` (dato personal,
[ADR-0005](adrs/0005-reporte-anonimo-con-contacto-opcional.md)), `ip_origen`, `creado_en`,
`incidencia_id` (nullable — nulo = pendiente en bandeja),
`agrupado_automaticamente` (bool, señal `AGRUPADO AUTO`),
`respuesta_duplicado_ciudadano` (señal de E3, nunca decisión),
`borrador_id` (idempotencia de reintento, [ADR-0013](adrs/0013-resiliencia-borrador-local.md)).

### `Incidencia` — unidad de trabajo, única con estado
`id`, `folio`, `tipo_incidencia_id`, `ubicacion` (la del reporte primario), `zona_id`,
`estado` (`reportado` · `validado` · `asignado` · `en_proceso` · `resuelto` · `descartado`),
`causal_descarte` (obligatoria si `descartado`: rechazado · duplicado · fuera de ámbito),
`responsable_id`, `prioridad` (`ALTA`/`MEDIA`/`BAJA`), `plazo_en`, `escalada_en`, `creada_en`,
`resuelta_en`.
Relación 1..N con `Reporte` ([ADR-0004](adrs/0004-separacion-reporte-incidencia.md)); la asignación
cuelga de aquí, lo que hace estructuralmente imposible el responsable duplicado.

### `Evidencia`
`id`, `reporte_id` **o** `incidencia_id`, `tipo` (`REPORTE` / `CIERRE`), `ruta_relativa`,
`estado_carga` (`COMPLETA` / `PENDIENTE`), `tamano_bytes`, `mime`, `creada_en`.
Solo metadatos; el binario vive en disco
([ADR-0008](adrs/0008-evidencia-en-sistema-de-archivos.md)). La regla "`resuelto` exige al menos una
foto de cierre" es `EXISTS(Evidencia WHERE incidencia_id = ? AND tipo = 'CIERRE' AND estado_carga =
'COMPLETA')`.

### `HistorialIncidencia` — solo lectura, append-only
`id`, `incidencia_id`, `estado_anterior`, `estado_nuevo`, `actor_id` (nullable: el sistema es actor
en la auto-agrupación y el escalamiento), `actor_tipo` (`USUARIO` / `SISTEMA`), `comentario`,
`creado_en`.
Se escribe en la misma transacción que el cambio de estado.

### `Usuario` — solo roles internos
`id`, `nombre`, `email`, `hash_password`, `rol` (`VALIDADOR` / `RESPONSABLE` / `SUPERVISOR` /
`ADMIN`), `activo`. El ciudadano no tiene registro
([ADR-0005](adrs/0005-reporte-anonimo-con-contacto-opcional.md)).

### `Notificacion`
`id`, `usuario_id`, `incidencia_id`, `tipo` (`ASIGNACION` / `CAMBIO_ESTADO` / `ESCALAMIENTO`),
`leida_en`, `creada_en`. Solo internas; el PRD excluye avisos masivos a la ciudadanía.

### `ConfiguracionDuplicados`
`radio_estricto_m`, `ventana_estricta_min`, `radio_sugerencia_m`, `ventana_sugerencia_min`.
Configuración persistida, no constantes: el PRD exige radio y ventana "configurables"
([ADR-0012](adrs/0012-deteccion-de-duplicados.md)).

### Cobertura de los elementos de interfaz del Design.md

| Elemento de UI | Respaldo en el modelo |
|---|---|
| Folio citable (03) | `Reporte.folio` |
| Zona, antigüedad, plazo en `label-mono` (Incident Card) | `zona_id`, `creado_en`, `Incidencia.plazo_en` |
| Distancia en el comparador (05) | Calculada en consulta (`ST_Distance`), no persistida |
| `VENCIDO` / cola de >48 h (04) | `Incidencia.plazo_en` vs. ahora |
| `DUPLICADO?` / `AGRUPADO AUTO` | `Reporte.agrupado_automaticamente`, candidatos por `ST_DWithin` |
| `FUERA ÁMB.` (E4) | `Reporte.fuera_de_ambito` |
| `ALTA` / `MEDIA` / `BAJA` (06) | `Incidencia.prioridad` |
| Miniatura `PENDIENTE` con % (E2) | `Evidencia.estado_carga` |
| State Machine horizontal y vertical | `Incidencia.estado` + `HistorialIncidencia` |
| Mapa de calor y conteo por zona (10) | `ubicacion` + `zona_id` agregados |
| Marca de actualización (10) | Marca temporal en la respuesta del endpoint de agregados |

## Criterios de aceptación por flujo

### Flujo 1 — Reporte ciudadano (pantallas 01–03, E1–E5)

- [ ] Un reporte se crea sin autenticación, enviando únicamente tipo de incidencia y ubicación.
- [ ] Denegado el permiso de geolocalización, el mapa permite fijar el punto manualmente y el envío
      procede igual (E1).
- [ ] La respuesta de creación devuelve un folio legible, y ese folio permite consultar el estado sin
      credenciales.
- [ ] Un reporte creado tiene siempre `ubicacion` no nula y un `tipo_incidencia_id` existente en el
      catálogo activo.
- [ ] Si las coordenadas caen dentro de una zona activa, `zona_id` se resuelve automáticamente; si
      caen fuera de toda zona, el reporte se persiste con `zona_id` nulo y `fuera_de_ambito = true`,
      y llega a la bandeja marcado `FUERA ÁMB.` (E4).
- [ ] Una fotografía que falla al subirse deja una `Evidencia` en estado `PENDIENTE` y el reporte
      permanece válido y consultable por su folio (E2).
- [ ] Perdida la conexión, el contenido de los tres pasos se recupera al reabrir la aplicación en el
      mismo navegador (E5).
- [ ] Dos envíos con el mismo `borrador_id` producen un único `Reporte`.
- [ ] Al elegir tipo y ubicación, se muestran los reportes cercanos del mismo tipo dentro del radio
      de sugerencia; la respuesta del ciudadano se persiste sin alterar el destino del reporte (E3).
- [ ] Ningún viewport desde 360px produce scroll horizontal en las pantallas 01–03.

### Flujo 2 — Validación y duplicados (pantallas 04–05)

- [ ] La bandeja lista exactamente los reportes con `incidencia_id` nulo, más las incidencias con
      señal `AGRUPADO AUTO` sin confirmar.
- [ ] Validar un reporte crea su `Incidencia` en estado `validado` y escribe entrada de historial.
- [ ] Un reporte que ingresa dentro del radio y la ventana **estrictos**, con el mismo tipo y contra
      una incidencia abierta, se adjunta a esa incidencia sin crear una nueva y queda marcado
      `AGRUPADO AUTO`, con entrada de historial cuyo `actor_tipo` es `SISTEMA`.
- [ ] Desagrupar un reporte lo devuelve a la bandeja con `incidencia_id` nulo, sin modificar el
      estado ni borrar el historial de la incidencia de origen.
- [ ] Cambiar radio o ventana en el comparador recalcula los candidatos sin recargar la vista y sin
      modificar dato alguno.
- [ ] Una incidencia con N reportes agrupados admite exactamente un `responsable_id`.
- [ ] Rechazar un reporte exige causal; sin causal la operación falla con error de validación.
- [ ] Los umbrales se leen de `ConfiguracionDuplicados`; cambiarlos no requiere despliegue.
- [ ] Un usuario con rol distinto de `VALIDADOR` (o `ADMIN`) recibe 403 en todos los endpoints de
      este flujo, verificado con prueba de integración.

### Flujo 3 — Asignación, atención y cierre (pantallas 06–08)

- [ ] Asignar exige responsable, prioridad y plazo en la misma operación; falta cualquiera de los
      tres y la operación falla.
- [ ] La transición a `asignado` genera una `Notificacion` de tipo `ASIGNACION` para el responsable.
- [ ] Solo se aceptan las transiciones del modelo de estados del Design.md; cualquier otra devuelve
      error de dominio, verificado con prueba unitaria por cada par origen-destino inválido.
- [ ] Pasar a `resuelto` sin al menos una `Evidencia` de tipo `CIERRE` en estado `COMPLETA` falla, y
      la interfaz anuncia el requisito antes de que el usuario lo intente.
- [ ] Pasar a `descartado` sin `causal_descarte` falla.
- [ ] Toda transición aceptada escribe, en la misma transacción, una entrada de historial con
      estado anterior, estado nuevo, actor y fecha-hora. No existe incidencia cuyo número de
      transiciones difiera de su número de entradas de historial.
- [ ] El historial no admite modificación ni borrado por ningún rol.

### Flujo 4 — Escalamiento y notificaciones (pantalla 09)

- [ ] El job periódico detecta las incidencias cuyo `plazo_en` venció y que no están en `resuelto`
      ni `descartado`, y genera notificación de `ESCALAMIENTO` al supervisor y al responsable.
- [ ] Una incidencia ya escalada no genera notificación repetida en cada ejecución del job
      (`escalada_en` no nulo).
- [ ] La incidencia vencida aparece en la cola de vencidos de la pantalla 04.
- [ ] El escalamiento queda registrado en el historial con `actor_tipo = SISTEMA`.
- [ ] El contador de notificaciones no leídas se refresca en el cliente en 30 segundos o menos.

### Flujo 5 — Dashboard (pantalla 10)

- [ ] El dashboard devuelve conteo de incidencias por estado, por tipo y por zona.
- [ ] La respuesta incluye una marca temporal de generación, y la interfaz la muestra.
- [ ] El tiempo entre un cambio de estado y su reflejo en el dashboard es menor a 5 minutos,
      verificable como intervalo de refresco configurado ≤ 60 s.
- [ ] El mapa de calor se construye sobre las coordenadas reales de las incidencias, sin agregación
      manual de zona.
- [ ] Un usuario sin rol `SUPERVISOR` (o `ADMIN`) recibe 403 en los endpoints de agregados.

### Flujo 6 — Transversales

- [ ] Ningún endpoint que modifique datos es accesible sin cookie de sesión válida, salvo la
      creación de reporte y la consulta por folio.
- [ ] El token de sesión no es legible desde JavaScript (cookie `httpOnly`).
- [ ] El esquema OpenAPI se genera desde el código de la API y el cliente de Angular se genera desde
      ese esquema en el build; un DTO incompatible rompe la compilación del frontend.
- [ ] El contacto opcional del ciudadano no aparece en listados, exportaciones ni respuestas de
      agregados.
- [ ] Ninguna pantalla produce scroll horizontal desde 360px; los objetivos táctiles en móvil miden
      al menos 44px de alto.

## Riesgos técnicos abiertos

- **Umbrales de duplicado sin calibrar.** El PRD reconoce que "el criterio exacto de *similar* debe
  afinarse con el equipo funcional", y la [ADR-0012](adrs/0012-deteccion-de-duplicados.md) los
  automatiza parcialmente. Deben arrancar deliberadamente conservadores y revisarse con datos
  reales; hasta entonces, la señal `AGRUPADO AUTO` es la única red de seguridad.
- **`AGRUPADO AUTO` no existe en el Design.md.** La auto-agrupación introduce una señal y una acción
  de desagrupar en la pantalla 04, y cambia el propósito de la 05 de "agrupar" a "revisar lo
  agrupado". Hay que reflejarlo antes de alta fidelidad.
- **Plazo por tipo de incidencia sin definir.** Es el pendiente #4 del Design.md y el disparador de
  todo el flujo de escalamiento. `TipoIncidencia.plazo_por_defecto_horas` deja el lugar preparado,
  pero los valores los debe fijar el equipo operativo.
- **Polígonos de zona por conseguir.** La [ADR-0006](adrs/0006-zona-como-catalogo-de-poligonos.md)
  depende de datos geográficos oficiales del ámbito elegido. Sin ellos, el conteo por zona del
  dashboard no funciona. Ligado al pendiente #1 del Design.md (ámbito exacto y multi-zona).
- **Despliegue de instancia única.** Scheduler embebido ([ADR-0002](adrs/0002-stack-nestjs-typescript.md))
  y evidencia en disco local ([ADR-0008](adrs/0008-evidencia-en-sistema-de-archivos.md)) impiden
  escalar horizontalmente sin revisar ambas decisiones.
- **Crecimiento del disco de evidencia sin dimensionar.** El PRD marca el volumen de fotografías
  como riesgo abierto y la ADR-0008 lo concentra en un disco. Requiere monitoreo de espacio libre y
  una política de retención o compresión; un disco lleno deja de aceptar evidencia.
- **Administración de usuarios por construir.** El pendiente #6 del Design.md no se cubrió en
  diseño, y la [ADR-0007](adrs/0007-autenticacion-y-autorizacion.md) la asume como código propio:
  alta, cambio y recuperación de contraseña, y desactivación.
- **Reportante reincidente débilmente detectable.** La huella por IP de la
  [ADR-0005](adrs/0005-reporte-anonimo-con-contacto-opcional.md) es una señal para el validador, no
  un criterio automático. Si el abuso resulta real en operación, esa decisión debe revisarse.
- **Contacto opcional como dato personal.** Falta definir período de retención y responsable del
  tratamiento.
