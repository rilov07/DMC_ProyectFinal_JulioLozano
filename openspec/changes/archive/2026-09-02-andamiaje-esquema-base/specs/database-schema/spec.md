# Database Schema Specification

## Purpose

Provide a versioned, TypeORM-managed PostGIS schema for GeoReport Vial that reproduces the structure of the reference model in `db/01-schema.sql` (tables, enum types, indexes, constraints) without the business-rule triggers/functions, which are deferred to the NestJS domain layer in future backlog items.

## Requirements

### Requirement: PostGIS Container Starts Healthy

`docker compose up` MUST bring up a PostGIS container that becomes healthy, reachable on the documented host port, without auto-mounting raw SQL scripts into `docker-entrypoint-initdb.d`.

#### Scenario: Compose brings up a healthy database

- GIVEN Docker and Docker Compose are available
- WHEN `docker compose up -d` is run against the project's compose file
- THEN the `postgis/postgis:16-3.4` container reaches healthy status
- AND PostgreSQL is reachable on host port 5433
- AND no `db/01-schema.sql` or `db/02-seed.sql` file is auto-executed via `docker-entrypoint-initdb.d`

### Requirement: Migrations Reproduce Reference Structure

Running the TypeORM migrations against a freshly created, empty PostGIS database MUST create exactly the enum types, tables, columns, constraints, and indexes defined in `db/01-schema.sql`, and MUST NOT create the business-rule triggers or functions (`fn_historial_inmutable`, `fn_registrar_historial`, `fn_resuelto_exige_evidencia`, `fn_transicion_valida`, `fn_ingresar_reporte`, `fn_desagrupar_reporte`).

#### Scenario: Migrations run clean on an empty database

- GIVEN a freshly created PostGIS container with no application schema
- WHEN the migration command is run (e.g. `npm run -w georeport-api migration:run`)
- THEN all migrations apply without error
- AND every table from `db/01-schema.sql` exists (`zona`, `tipo_incidencia`, `usuario`, `configuracion_duplicados`, `incidencia`, `reporte`, `evidencia`, `historial_incidencia`, `notificacion`)
- AND every enum type from `db/01-schema.sql` exists with the same allowed values

#### Scenario: Constraints and indexes match the reference structure

- GIVEN migrations have been applied
- WHEN the database catalog is inspected
- THEN all CHECK constraints from `db/01-schema.sql` are present (e.g. `chk_descarte_exige_causal`, `chk_asignacion_completa`, `chk_resuelta_en_coherente`, `chk_evidencia_dueno_unico`, `chk_evidencia_tipo_coherente`, `chk_actor_coherente`)
- AND all indexes from `db/01-schema.sql` are present, including the GIST spatial indexes on `zona.poligono`, `incidencia.ubicacion`, and `reporte.ubicacion`

#### Scenario: No business trigger or function is migrated

- GIVEN migrations have been applied
- WHEN the database's triggers and functions are inspected
- THEN none of `fn_historial_inmutable`, `fn_registrar_historial`, `fn_resuelto_exige_evidencia`, `fn_transicion_valida`, `fn_ingresar_reporte`, or `fn_desagrupar_reporte` exist
- AND no trigger references any of these functions

### Requirement: Migrations Are Repeatable

Migrations MUST be runnable from a clean state and MUST be reversible via a documented rollback path.

#### Scenario: Migrations re-run cleanly after a full reset

- GIVEN a PostGIS volume has been destroyed and recreated
- WHEN migrations are run again from scratch
- THEN the resulting schema is identical to the first run
- AND no manual intervention is required

### Requirement: Spatial Columns Use Geography Types

Columns storing geographic data MUST use PostGIS `geography` types consistent with `db/01-schema.sql` (`Polygon, 4326` for `zona.poligono`; `Point, 4326` for `incidencia.ubicacion` and `reporte.ubicacion`), and spatial queries MUST remain outside ORM query-builder abstractions per ADR-0002/ADR-0003.

#### Scenario: Geography columns are created with correct type and SRID

- GIVEN migrations have been applied
- WHEN the column type of `zona.poligono`, `incidencia.ubicacion`, and `reporte.ubicacion` is inspected
- THEN each is a PostGIS `geography` column with SRID 4326 and the geometry subtype documented in `db/01-schema.sql`
