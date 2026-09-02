# Catalog Seed Specification

## Purpose

Load the production-adjacent catalog data (`tipo_incidencia`, `configuracion_duplicados`) needed for the application to function, while keeping development-only fixtures (`zona`, `usuario`) clearly separated and never mistaken for production data.

## Requirements

### Requirement: Catalog Seed Loads Incident Type Catalog

The catalog seed MUST insert exactly the 12 `tipo_incidencia` rows from `db/02-seed.sql`, with their documented `nombre` and `plazo_por_defecto_horas` values, and MUST be idempotent (safe to run more than once without duplicating or erroring).

#### Scenario: Catalog seed loads all incident types

- GIVEN migrations have been applied and `tipo_incidencia` is empty
- WHEN the catalog seed command is run
- THEN exactly 12 rows exist in `tipo_incidencia`
- AND each row's `nombre` and `plazo_por_defecto_horas` match the values documented in `db/02-seed.sql`
- AND every row has `activo = true`

#### Scenario: Catalog seed is safe to re-run

- GIVEN the catalog seed has already been run once successfully
- WHEN the catalog seed command is run again
- THEN no duplicate `tipo_incidencia` rows are created
- AND the command completes without error

### Requirement: Catalog Seed Loads Duplicate-Detection Configuration

The catalog seed MUST insert exactly one `configuracion_duplicados` row (`id = 1`) with the conservative defaults from ADR-0012: `radio_estricto_m = 20`, `ventana_estricta_min = 120`, `radio_sugerencia_m = 150`, `ventana_sugerencia_min = 2880`.

#### Scenario: Duplicate-detection config loads with documented defaults

- GIVEN migrations have been applied and `configuracion_duplicados` is empty
- WHEN the catalog seed command is run
- THEN exactly one row exists with `id = 1`
- AND its four threshold columns match the ADR-0012 defaults exactly

### Requirement: Development Fixtures Are Loaded Separately From Catalog Seed

Loading `zona` and `usuario` fixture rows MUST use a distinct command or explicit flag from the catalog seed, and MUST be documented as non-production data in the project README.

#### Scenario: Running the catalog seed alone does not load fixtures

- GIVEN a freshly migrated, empty database
- WHEN only the catalog seed command is run (no fixture flag/command)
- THEN `tipo_incidencia` and `configuracion_duplicados` are populated
- AND `zona` and `usuario` remain empty

#### Scenario: Fixture command loads placeholder zones and users

- GIVEN a freshly migrated, empty database
- WHEN the separate fixture command (or catalog seed with the fixture flag) is run
- THEN exactly 3 `zona` rows are created, matching the placeholder polygons in `db/02-seed.sql`
- AND exactly 5 `usuario` rows are created, matching the placeholder accounts in `db/02-seed.sql`
- AND the command's output or documentation explicitly labels this data as non-production

#### Scenario: README documents the non-production nature of fixtures

- GIVEN the project README
- WHEN the seed/fixture sections are read
- THEN it explicitly states that `zona` and `usuario` fixture data are placeholders, not production data, and names the separate command/flag used to load them
