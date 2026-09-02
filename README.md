# GeoReport Vial

Monorepo (npm workspaces) for `georeport-api` (NestJS + TypeORM + PostGIS) and `georeport-web`
(Angular, standalone + signals). This is backlog item #1, **Andamiaje y esquema de base**: a
runnable scaffold with a real database — no business endpoints, auth, or UI yet (see
`openspec/changes/andamiaje-esquema-base/proposal.md`).

No shared-types package exists between the two apps (ADR-0009); the contract stays OpenAPI.

## Prerequisites

- Node.js 22 LTS (see `.nvmrc`)
- Docker / Docker Compose

## Setup

```bash
npm install                      # installs both workspaces from the root
cp .env.example .env             # DB_HOST/DB_PORT/DB_USER/DB_PASSWORD/DB_NAME, port 5433
npm run docker:up                # PostGIS 16-3.4 on :5433, waits for healthy
npm run migrate                  # applies TypeORM migrations (structure only, no business triggers)
npm run seed                     # catalog: 12 tipo_incidencia rows + 1 configuracion_duplicados row
```

`npm run db:reset` chains `docker:reset` (drops the volume) + `migrate` + `seed` + `seed:dev` in one
command.

## Database and migrations

Migrations are hand-written (`georeport-api/src/database/migrations/`), porting the structure of
`db/01-schema.sql` — tables, enum types, indexes, constraints — **without** the business-rule
triggers/functions (`fn_historial_inmutable`, `fn_registrar_historial`,
`fn_resuelto_exige_evidencia`, `fn_transicion_valida`, `fn_ingresar_reporte`,
`fn_desagrupar_reporte`). Those rules move to the NestJS domain layer in later backlog items
(#10-#14); `db/README.md` documents the deliberate difference. `georeport-api/test/database.e2e-spec.ts`
asserts both the schema parity and that no such trigger/function was migrated.

Spatial columns (`zona.poligono`, `incidencia.ubicacion`, `reporte.ubicacion`) are PostGIS
`geography` with SRID 4326; per ADR-0002/ADR-0003, they are never read/written through the ORM
(`select/insert/update: false` on every spatial column) — only through raw SQL.

## Seed data — NOT PRODUCTION DATA warning

| Command                                  | Data                                                                               | Safe in production?                                                                                  |
| ---------------------------------------- | ---------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `npm run seed` (`seed:catalog`)          | `tipo_incidencia` (12 rows), `configuracion_duplicados` (1 row, ADR-0012 defaults) | Yes — idempotent, safe anywhere                                                                      |
| `npm run seed:dev` (`seed:dev-fixtures`) | `zona` (3 placeholder rectangles over Lima), `usuario` (5 placeholder accounts)    | **No.** Refuses to run (exits `1`, prints a `NOT PRODUCTION DATA` banner) when `NODE_ENV=production` |

`zona` and `usuario` fixtures are placeholders for local development and tests — see `db/README.md`
for the real-data risk this is deferring.

## Root scripts

| Script                                               | What it does                                                     |
| ---------------------------------------------------- | ---------------------------------------------------------------- |
| `npm install`                                        | Installs both workspaces                                         |
| `npm run build` / `test` / `lint`                    | Runs the script in both workspaces (`--workspaces --if-present`) |
| `npm run format` / `format:check`                    | Prettier over the scaffold (shared root config)                  |
| `npm run docker:up` / `docker:down` / `docker:reset` | PostGIS container lifecycle                                      |
| `npm run migrate` / `migrate:revert`                 | TypeORM migrations                                               |
| `npm run seed` / `seed:dev`                          | Catalog seed / dev-fixtures seed (see warning above)             |
| `npm run db:reset`                                   | `docker:reset` + `migrate` + `seed` + `seed:dev`                 |
| `npm run start:api` / `start:web`                    | Dev servers for each app                                         |

## Testing

Both workspaces use Jest via its own CLI (not the Angular unit-test builder). `georeport-api`'s unit
suite (`npm run -w georeport-api test`) has no DB dependency; its integration suite
(`npm run -w georeport-api test:e2e`) requires a live, migrated PostGIS container
(`npm run db:reset` first).
