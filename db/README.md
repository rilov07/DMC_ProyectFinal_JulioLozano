# Modelo de datos de prueba — GeoReport Vial

Implementación en SQL del modelo descrito en [`../TECH-DESIGN.md`](../TECH-DESIGN.md). Sirve para
verificar que las decisiones de arquitectura se sostienen sobre datos reales antes de escribir una
línea de `georeport-api`.

> **Estado: sin ejecutar.** Estos scripts todavía no se han corrido contra una base PostGIS —
> Docker Desktop no estaba levantado en la máquina al momento de escribirlos. Ver
> [Verificación pendiente](#verificación-pendiente).

## Archivos

| Archivo | Contenido |
|---|---|
| `01-schema.sql` | Las 9 tablas, índices GiST, invariantes de dominio como triggers y las funciones de ingreso y desagrupación de reportes. |
| `02-seed.sql` | Catálogo del PRD, zonas, usuarios internos y un escenario que ejercita los casos borde E2, E3, E4 y E5. |
| `03-consultas-prueba.sql` | Once consultas de verificación, cinco pruebas negativas y la prueba de reversibilidad de la auto-agrupación. |
| `docker-compose.yml` | PostGIS 16 en el puerto **5433**, con `01` y `02` ejecutados al crear el volumen. |

## Cómo levantarlo

```bash
docker compose -f db/docker-compose.yml up -d --wait
docker exec -i georeport-db psql -U georeport -d georeport < db/03-consultas-prueba.sql
```

Para empezar de cero (borra el volumen y sus datos):

```bash
docker compose -f db/docker-compose.yml down -v
```

## Qué demuestra cada cosa

**Decisiones de arquitectura llevadas a esquema**

- **ADR-0003 (PostGIS).** `geography(Point,4326)` con índice GiST; duplicados por `ST_DWithin` con
  radio en metros reales y zona por `ST_Covers`.
- **ADR-0004 (Reporte ≠ Incidencia).** `reporte.incidencia_id` nulo = pendiente en bandeja. El
  estado, el responsable y el historial cuelgan solo de `incidencia`, lo que hace
  **estructuralmente imposible** el responsable duplicado que el PRD prohíbe.
- **ADR-0005 (ciudadano anónimo).** `usuario` contiene únicamente roles internos; el reporte lleva
  `contacto_opcional` e `ip_origen`.
- **ADR-0006 (zona derivada).** `fn_ingresar_reporte` resuelve `zona_id` a partir de las
  coordenadas; nadie la elige. Fuera de toda zona ⇒ `fuera_de_ambito = true`.
- **ADR-0012 (auto-agrupación reversible).** Umbrales en `configuracion_duplicados`, no en el
  código. `fn_desagrupar_reporte` devuelve el reporte a la bandeja sin tocar estado ni historial.
- **ADR-0013 (borrador).** `reporte.borrador_id` único: dos envíos del mismo borrador producen un
  solo reporte.

**Reglas de negocio como invariantes verificables**

| Regla | Origen | Mecanismo |
|---|---|---|
| El historial es de solo lectura | PRD + Design.md | Trigger que rechaza `UPDATE` y `DELETE` |
| Toda transición escribe historial | Criterio de éxito del PRD | Trigger `AFTER UPDATE OF estado`, misma transacción |
| Solo transiciones del modelo de estados | Design.md | Trigger con la tabla de transiciones permitidas |
| `resuelto` exige foto de cierre completa | Design.md | Trigger que cruza con `evidencia` |
| `descartado` exige causal | Design.md | `CHECK` |
| Asignar exige responsable + prioridad + plazo juntos | Design.md, pantalla 06 | `CHECK` |

Las cinco pruebas negativas de `03-consultas-prueba.sql` intentan violar cada una de esas reglas y
deben imprimir `OK — rechazado: <mensaje>`. Si alguna imprime `FALLO`, el modelo no cumple.

## Diferencia deliberada con el sistema real

En `georeport-api` estas reglas viven en la capa de dominio en NestJS
([ADR-0001](../adrs/0001-topologia-spa-angular-mas-api-propia.md)), no en la base. Aquí se
implementan como triggers para que **este modelo sea verificable por sí solo**, sin depender de que
exista el backend. Al construir la API, quedan como red de seguridad de último recurso, no como el
lugar donde vive la lógica.

## Advertencias

- **Los polígonos de zona son rectángulos inventados sobre Lima**, no límites distritales oficiales.
  Conseguir los reales es un riesgo abierto declarado en el TDD y el pendiente #1 del Design.md.
- **Los plazos por tipo de incidencia son valores de partida**, no acordados con el equipo
  operativo (pendiente #4 del Design.md). Disparan todo el escalamiento, así que importan.
- **Los umbrales de duplicado arrancan conservadores** (20 m / 120 min para agrupar) porque el PRD
  reconoce que el criterio de "similar" aún no está afinado.
- Los `hash_password` del seed son marcadores de posición, no hashes válidos.

## Verificación pendiente

Los scripts se escribieron pero no se ejecutaron. Para verificarlos, levantá el daemon de Docker y
corré los dos comandos de arriba: el resultado esperado es que las once consultas devuelvan filas
coherentes y que las cinco pruebas negativas impriman `OK — rechazado`.
