# Design: Andamiaje y esquema de base

## Technical Approach

npm workspaces root orchestrating two CLI-scaffolded apps. `db/01-schema.sql` is ported **by hand** into TypeORM migrations as pure structure; the four business trigger/function blocks are excluded and guarded by an integration assertion. TypeORM owns the relational surface; every PostGIS column and query stays raw SQL (ADR-0002 cost note, ADR-0003). Domain identifiers stay Spanish, matching the existing schema.

> Correction to the change brief: `db/01-schema.sql` uses `geography(Point,4326)` / `geography(Polygon,4326)`, not `geometry`. ADR-0003 depends on `geography` (metre-accurate `ST_DWithin`). Migrations MUST emit `geography`.

## Architecture Decisions

| # | Decision | Choice | Rejected | Rationale |
|---|---|---|---|---|
| 1 | Package manager | **npm workspaces** | pnpm; Nx/Turborepo | Ships with Node; `npm run -w` already in the proposal's success criteria; hoisted `node_modules` is what Angular/Nest CLIs assume. Nx/Turborepo is the build tooling ADR-0009 cited when rejecting the shared-types monorepo. |
| 2 | Migration authoring | **Hand-written `queryRunner.query()` with SQL copied from `db/01-schema.sql`** | `typeorm migration:generate` | `generate` diffs entities and silently drops what matters here: `geography` + SRID, GiST indexes, the five partial indexes (`WHERE estado NOT IN (...)`), table-level `CHECK`s, and the `folio` sequence defaults. Hand-written SQL makes review a literal text diff against the reference. No `migration:generate` script is defined; `synchronize` is `false`. |
| 3 | Trigger exclusion | **Structure only; `fn_historial_inmutable`, `fn_registrar_historial`, `fn_transicion_valida`, `fn_resuelto_exige_evidencia`, `fn_ingresar_reporte`, `fn_desagrupar_reporte` omitted** | Port triggers as a safety net | `db/README.md` §"Diferencia deliberada" says these belong in the NestJS domain layer. Duplicating them would conflict with items #10–#14. Enforced by a test asserting zero non-internal triggers and zero `public.fn_*` functions. |
| 4 | Spatial columns in entities | **Declared `geography` but `select/insert/update: false`** | TypeORM GeoJSON transform; omit column entirely | TypeORM wraps spatial columns in `ST_AsGeoJSON`/`ST_GeomFromGeoJSON`, which is unreliable for `geography`+SRID. Flagging them off makes `repository.save()` on a `NOT NULL` spatial row fail loudly, forcing raw SQL — the ADR-0003 rule becomes structural, not a convention. |
| 5 | Seed separation | **Two named scripts, no flag** | One script + `--fixtures` | A flag reaches the dangerous path via typo. `seed:catalog` is idempotent and production-safe; `seed:dev-fixtures` must be asked for by name and exits non-zero when `NODE_ENV=production`. |
| 6 | Web test runner | **Jest via its own CLI** (`jest-preset-angular`), Karma removed from `angular.json` | Karma/Jasmine; Angular's `unit-test` builder | Karma is deprecated by the Angular team and needs headless Chrome. Jest gives a one-person team one runner/assertion/mock dialect across both apps. Run through the plain Jest CLI, **not** the Angular builder, whose Jest support is experimental. Vitest is the likely future migration but is outside this change's decided domain. |
| 7 | Lint/format layout | **Prettier shared at root; ESLint per workspace** | Shared root ESLint base | Formatting has no framework dimension — one `.prettierrc.json` cascades. ESLint genuinely differs (`typescript-eslint` vs `@angular-eslint` + template parser) and plugin resolution across workspaces is fragile. Both keep `eslint-config-prettier`. |
| 8 | Compose file | **New root `docker-compose.yml`, distinct volume `georeport-api-data`; `db/docker-compose.yml` untouched** | Edit `db/docker-compose.yml` | Same image/port/healthcheck/container name, but **no `docker-entrypoint-initdb.d` mounts**. A distinct volume is a correctness requirement: reusing `georeport-data` would run migrations on top of a schema `01-schema.sql` already created. Identical container name + port 5433 makes the two mutually exclusive by construction. |

## Data Flow

    db/01-schema.sql --(hand port, structure only)--> georeport-api/src/database/migrations/*.ts
    db/02-seed.sql   --(12 catalog rows + 1 config)--> seeds/data/tipo-incidencia.catalog.ts
                     --(3 zonas + 5 usuarios)-------> seeds/data/dev-fixtures.ts   [DEV ONLY]

    npm run docker:up  --> georeport-db (postgis/postgis:16-3.4, :5433) --wait healthy
                                  |
        npm run migrate ----------+--> AppDataSource (synchronize:false, migrationsRun:false)
        npm run seed -------------+
        npm run seed:dev ---------+

## File Changes

| File | Action | Description |
|---|---|---|
| `package.json`, `package-lock.json` | Create | Private root, `workspaces: ["georeport-api","georeport-web"]`, orchestration scripts |
| `.nvmrc`, `.editorconfig` | Create | Node 22 LTS pin; shared whitespace rules |
| `.prettierrc.json`, `.prettierignore` | Create | Single shared formatter config |
| `docker-compose.yml` | Create | PostGIS 16-3.4, `:5433`, healthcheck, volume `georeport-api-data`, **no** initdb mounts |
| `.env.example` | Create | `DB_HOST/DB_PORT/DB_USER/DB_PASSWORD/DB_NAME`, all `georeport`, port `5433` |
| `georeport-api/` (Nest CLI scaffold) | Create | `nest-cli.json`, `tsconfig*.json`, `eslint.config.mjs`, `src/main.ts`, `src/app.*` |
| `georeport-api/jest.config.ts` | Create | Unit config, `roots: ['<rootDir>/src']`, DB-free |
| `georeport-api/test/jest-e2e.json` | Create | Separate project for DB integration specs |
| `georeport-api/src/config/database.config.ts` | Create | Env-driven `DataSourceOptions` shared by Nest and the CLI |
| `georeport-api/src/database/data-source.ts` | Create | `export default new DataSource(...)` for the TypeORM CLI |
| `georeport-api/src/database/entities/*.entity.ts` | Create | 9 entities: `zona`, `tipo-incidencia`, `usuario`, `configuracion-duplicados`, `incidencia`, `reporte`, `evidencia`, `historial-incidencia`, `notificacion` |
| `georeport-api/src/database/migrations/*-EnablePostgis.ts` | Create | `CREATE EXTENSION IF NOT EXISTS postgis` |
| `.../*-CreateSchema.ts` | Create | 8 ENUM types, 2 sequences, 9 tables, all `CHECK`/FK constraints. Header comment names the excluded functions and points at items #10–#14 |
| `.../*-CreateIndexes.ts` | Create | 3 GiST + btree + 5 partial indexes, isolated so the spatial diff is reviewable |
| `.../seeds/seed-catalog.ts`, `.../seeds/seed-dev-fixtures.ts`, `.../seeds/data/*.ts` | Create | Catalog vs fixtures, see Interfaces |
| `georeport-api/test/database.e2e-spec.ts` | Create | Schema-parity and trigger-absence assertions |
| `georeport-web/` (Angular CLI scaffold) | Create | Standalone + signals, `eslint.config.mjs`, `jest.config.ts`, `setup-jest.ts`; Karma deps and the `angular.json` `test` target removed |
| `db/README.md` | Modify | Note that root compose supersedes it for the dev loop and the two cannot run together |
| `db/01-schema.sql`, `db/02-seed.sql`, `db/docker-compose.yml` | Unchanged | Reference model, read-only source |

## Interfaces / Contracts

Spatial column pattern (every `geography` column in all entities):

```ts
// zona.entity.ts — ADR-0003: reads/writes go through raw SQL, never the ORM.
@Column({ type: 'geography', spatialFeatureType: 'Polygon', srid: 4326,
          select: false, insert: false, update: false })
poligono!: string;
```

Enum and DB-default patterns (bind to the *existing* Postgres type; never let TypeORM invent one):

```ts
@Column({ type: 'enum', enum: EstadoIncidencia, enumName: 'estado_incidencia', default: 'validado' })
estado!: EstadoIncidencia;

@Column({ type: 'text', insert: false, update: false }) folio!: string; // sequence DEFAULT, read via RETURNING
@PrimaryGeneratedColumn({ type: 'bigint' }) id!: string;                // bigint surfaces as string
@Column({ name: 'tipo_incidencia_id', type: 'int' }) tipoIncidenciaId!: number; // explicit snake_case, no naming-strategy dep
```

Seed contract:

| Script | npm command | Contents | Guard |
|---|---|---|---|
| `seed-catalog.ts` | `npm run -w georeport-api seed:catalog` | `tipo_incidencia` (12, `ON CONFLICT (nombre) DO NOTHING`), `configuracion_duplicados` (1 row, ADR-0012 defaults via `INSERT (id) VALUES (1) ON CONFLICT DO NOTHING`) | Idempotent; safe anywhere |
| `seed-dev-fixtures.ts` | `npm run -w georeport-api seed:dev-fixtures` | `zona` (3 placeholder rectangles via `ST_GeogFromText`), `usuario` (5 accounts, placeholder hashes) | Exits `1` if `NODE_ENV=production`; prints a `NOT PRODUCTION DATA` banner; file header cites `db/README.md` warnings |

Root scripts: `build` / `test` / `lint` (`--workspaces --if-present`), `format`, `format:check`, `docker:up` (`up -d --wait`), `docker:down`, `docker:reset` (`down -v` + up), `migrate`, `migrate:revert`, `seed`, `seed:dev`, `db:reset` (reset + migrate + seed + seed:dev), `start:api`, `start:web`. Install is plain `npm install` at the root — no script needed.

## Testing Strategy

| Layer | What to Test | Approach |
|---|---|---|
| Unit (API) | Scaffolded `AppController`/`AppService` | Jest + ts-jest, `testEnvironment: node`, **no DB** so `npm test` stays green without Docker |
| Unit (Web) | Scaffolded `AppComponent` | Jest + `jest-preset-angular`, jsdom, via Jest CLI |
| Integration (API↔DB) | Migrations apply clean on an empty container; 9 tables, 8 enum types, 3 GiST indexes, 5 partial indexes present; **0** non-internal triggers and **0** `public.fn_*` functions; `tipo_incidencia`=12, `configuracion_duplicados`=1; `seed:catalog` re-run changes no counts | `test:e2e` project after `npm run db:reset`; `pg_trigger`/`pg_proc`/`pg_indexes` catalog queries |
| E2E | N/A | No business flow exists in this change |

## Threat Matrix

N/A — no routing, VCS/PR automation, executable-file classification, or process-integration boundary. The only subprocess surface is fixed-argument npm scripts (`docker compose`, `ts-node`) invoked by a developer with no untrusted input or dynamic command construction. The one data-safety boundary — the dev-fixtures seed — is handled by the Decision 5 `NODE_ENV` guard and its RED test.

## Migration / Rollout

No data migration: greenfield. `docker compose down -v` plus `git revert` of this change removes everything. `db/` keeps working standalone and is not modified except for a README note.

## Open Questions

- [ ] Angular major version the CLI scaffolds and its `jest-preset-angular` compatibility (zoneless/ESM) — verify at apply time; fall back to Karma only if Jest cannot be made green.
- [ ] `specs/database-schema/` and `specs/catalog-seed/` are declared in the proposal but only `specs/project-scaffolding/spec.md` exists.
- [ ] `db/01-schema.sql` has never been executed; the first migration run is also its first real validation.
