# Backlog: GeoReport Vial

Despiece de [`PRD.md`](PRD.md) y [`TECH-DESIGN.md`](TECH-DESIGN.md) (+ [`adrs/`](adrs/)) en ítems
implementables. El orden es por dependencia técnica, no por prioridad de negocio: lo que otros ítems
necesitan va primero.

| # | Item | Alcance | Depende de | Contexto extra requerido |
|---|---|---|---|---|
| 1 | Andamiaje y esquema de base | Monorepo `georeport-api` (NestJS) + `georeport-web` (Angular), PostGIS en Docker, migraciones derivadas de `db/01-schema.sql`, seed de catálogo | — | — |
| 2 | Autenticación de roles internos | Login usuario/contraseña, JWT en cookie `httpOnly`/`Secure`/`SameSite=Lax`, guards por rol, CORS con credenciales, token anti-CSRF (ADR-0007) | #1 | — |
| 3 | Administración de usuarios internos | Alta, desactivación, cambio y recuperación de contraseña (pendiente #6 del Design.md, riesgo abierto del TDD) | #2 | — |
| 4 | Contrato OpenAPI y shell de la SPA | Esquema generado desde el código de la API, cliente Angular generado en el build, layout responsivo del sistema visual "Industry", estado con Signals (ADR-0009, ADR-0010) | #1, #2 | — |
| 5 | Catálogos y configuración operativa | `TipoIncidencia` con `plazo_por_defecto_horas`, `Zona` como catálogo de polígonos, `ConfiguracionDuplicados` editable sin despliegue (ADR-0006, ADR-0012) | #1 | Polígonos oficiales del ámbito geográfico (pendiente #1 del Design.md) — los plazos por tipo ya están documentados |
| 6 | API pública de reporte | Creación anónima con resolución automática de zona (`ST_Covers`), `fuera_de_ambito`, folio citable, idempotencia por `borrador_id`; consulta de estado por folio sin credenciales | #5 | — |
| 7 | Evidencia fotográfica | Carga al volumen de disco, metadatos en `Evidencia`, `estado_carga = PENDIENTE` con reintento (ADR-0008, caso borde E2) | #6 | — |
| 8 | Reporte ciudadano en la web (01–03) | Mapa Leaflet/OSM, geolocalización con punto manual (E1), formulario de tres pasos, borrador local y recuperación tras pérdida de conexión (E5), confirmación con folio | #4, #6, #7 | — |
| 9 | Sugerencia de duplicados al ciudadano (E3) | Reportes cercanos del mismo tipo dentro del radio de sugerencia; la respuesta del ciudadano se persiste como señal y nunca altera el destino del reporte | #8 | Criterio funcional de "incidencia similar" (riesgo abierto del PRD y del TDD) |
| 10 | Núcleo de Incidencia: estados e historial | Máquina de estados (`reportado` → `validado` → `asignado` → `en_proceso` → `resuelto`/`descartado`), transiciones válidas y solo esas, `HistorialIncidencia` append-only escrito en la misma transacción | #2, #5 | — |
| 11 | Bandeja de validación (04) | Lista de reportes con `incidencia_id` nulo, validar creando la `Incidencia`, rechazar exigiendo causal, cola de vencidos y priorización de pendientes antiguos | #4, #10 | — |
| 12 | Auto-agrupación y comparador de duplicados (05) | Candidatos por `ST_DWithin` con umbrales estrictos, señal `AGRUPADO AUTO` con historial de actor `SISTEMA`, desagrupar reversible, recálculo en vivo de radio y ventana sin escribir datos (ADR-0012) | #11 | Criterio funcional de "incidencia similar" y calibración de radio/ventana |
| 13 | Asignación (06) | Responsable, prioridad y plazo exigidos en una sola operación; transición a `asignado`; un único `responsable_id` por incidencia aunque agrupe N reportes | #10, #11 | — |
| 14 | Atención y cierre (07–08) | Transición a `en_proceso` y a `resuelto` exigiendo al menos una `Evidencia` de tipo `CIERRE` en estado `COMPLETA`; `descartado` con `causal_descarte` obligatoria | #7, #13 | — |
| 15 | Notificaciones internas (09) | Notificaciones de `ASIGNACION` y `CAMBIO_ESTADO`, centro de notificaciones, contador de no leídas refrescado por polling en ≤30 s (ADR-0011) | #13 | — |
| 16 | Job de escalamiento por plazo vencido | Scheduler embebido, detección de `plazo_en` vencido fuera de estados terminales, notificación de `ESCALAMIENTO` a responsable y supervisor, `escalada_en` para no repetir, historial con `actor_tipo = SISTEMA` | #15 | Política de escalamiento (a quién notificar y con qué margen); los plazos por tipo ya están documentados |
| 17 | Dashboard (10) | Agregados por estado, tipo y zona con marca temporal de generación, mapa de calor sobre coordenadas reales, refresco configurado ≤60 s, 403 sin rol `SUPERVISOR`/`ADMIN` | #4, #10 | — |

## Criterios transversales

Los criterios del **Flujo 6** del TDD no son un ítem aparte: se verifican dentro de cada ítem que los
toca.

- Ningún endpoint que modifique datos accesible sin sesión válida, salvo creación de reporte y
  consulta por folio → ítems #2, #6.
- Cliente Angular generado desde el esquema OpenAPI; un DTO incompatible rompe el build → ítem #4.
- `contacto_opcional` nunca aparece en listados, exportaciones ni agregados → ítems #11, #17.
- Sin scroll horizontal desde 360px y objetivos táctiles de al menos 44px → todo ítem con interfaz
  (#4, #8, #11, #12, #13, #14, #15, #17).

## Cómo usar este backlog

Cada ítem es una spec independiente. Al implementarlo, arrancá un ciclo de Spec-Driven Development
(`sdd-new` o el flujo equivalente de tu harness) usando **ese ítem** como el "change" — no el
proyecto completo. Si la columna "Contexto extra requerido" tiene algo, compartilo como contexto al
generar la spec de ese ítem.

Para los ítems #5, #9, #12 y #16: antes de generar la spec, compartí tu documentación de reglas de
negocio de ese dominio como contexto, si la tenés. Los plazos de atención por tipo de incidencia ya
están documentados y deben adjuntarse al especificar #5 y #16; los polígonos zonales oficiales y el
criterio de "incidencia similar" siguen abiertos y bloquean la calibración de #5, #9 y #12 —
arrancá con los valores conservadores del seed y dejá los umbrales en `ConfiguracionDuplicados`,
como ya prevé la ADR-0012.
