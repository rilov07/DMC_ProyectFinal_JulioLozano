# sdd-init/DMC_ProyectFinal_JulioLozano

**Detected**: 2026-09-02
**Persistence mode**: openspec (Engram MCP did not connect this session)

## Project

- Name: DMC_ProyectFinal_JulioLozano (product name: GeoReport Vial)
- Type: greenfield, planning-only — no application code exists yet.
- Root: `D:\Cursos\Desarrollo_software_AI-first_ Claude\Proyecto\DMC_ProyectFinal_JulioLozano`

## Existing artifacts

- `PRD.md`, `PRD_Julio_Lozano.txt` — product requirements
- `TECH-DESIGN.md` — Technical Design Document
- `adrs/0001..0013-*.md` — 13 accepted ADRs (MADR format)
- `BACKLOG.md` — ordered backlog of implementable specs
- `Desing.md`, `GeoReport Vial - Wireframes.html` — UI/UX reference
- `db/01-schema.sql`, `db/02-seed.sql`, `db/03-consultas-prueba.sql`, `db/docker-compose.yml` — reference PostgreSQL + PostGIS data model, seed data, and local Docker setup

## Target stack (per TECH-DESIGN.md / ADRs, not yet scaffolded)

- Monorepo with two deployables:
  - `georeport-api` — NestJS on Node.js + TypeScript (ADR-0002), owns domain logic, auth (JWT httpOnly cookie, ADR-0007), REST/OpenAPI contract (ADR-0009), scheduled escalation job.
  - `georeport-web` — Angular SPA with Signals (ADR-0010), Leaflet/OpenStreetMap, no business rules, polling-based freshness (ADR-0011).
- Persistence: PostgreSQL + PostGIS (ADR-0003), single-instance API due to embedded scheduler + local-disk evidence storage (ADR-0008).
- Deployment constraint: `georeport-api` is single-instance until scheduler/evidence-storage ADRs are revisited.

## Stack detection result

No `package.json`, `nest-cli.json`, `angular.json`, `go.mod`, `pyproject.toml`, or `Cargo.toml` found anywhere in the repo. Zero application projects discovered. Only pre-existing project-level skills under `.claude/skills/` and `.agents/skills/` (symlinked, identical set): `generar-backlog`, `generar-prd`, `generar-tech-design`.

## Strict TDD resolution

`strict_tdd: false` — fails closed per sdd-init decision gate because zero projects were discovered and no workspace-level test command exists. The user's global config declares Strict TDD Mode enabled, but that requires an explicit workspace-level test command covering every in-scope project, which does not exist yet in this greenfield repo. Revisit once `georeport-api`/`georeport-web` are scaffolded with real test runners (e.g. Jest for NestJS, Karma/Jest for Angular).

## Next recommended step

`sdd-explore` or `sdd-new` against the first `BACKLOG.md` item to start the first SDD change and scaffold `georeport-api`/`georeport-web`.
