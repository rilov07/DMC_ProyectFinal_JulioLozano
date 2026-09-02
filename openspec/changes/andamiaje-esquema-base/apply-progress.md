# Apply Progress: Andamiaje y esquema de base

**Status**: 46/46 tasks complete (all 7 phases). Delivered as a single PR under `size:exception` (user-accepted; forecast was `400-line budget risk: High`, `Chained PRs recommended: Yes`).

## TDD Cycle Evidence (design-mandated RED/GREEN pairs)

| Pair | RED | GREEN | Evidence |
|---|---|---|---|
| Schema parity (5.1-5.4) | `database.e2e-spec.ts` asserting 9 tables/8 enums/CHECK/GiST-partial indexes, written before running migrations against a fresh container | `npm run migrate` + `npm run -w georeport-api test:e2e` — first run failed on 2 false positives (TypeORM's `migrations` table, PostGIS's `spatial_ref_sys`); excluded by name; re-run passed | `PASS test/database.e2e-spec.ts` (4/4 tests) |
| No business triggers/functions (5.5-5.6) | Same spec file asserting zero USER-defined `fn_*`/triggers | First run failed: PostGIS/postgis_topology (auto-installed by the `postgis/postgis` Docker image) own 788 functions + 1 trigger in `public`; fixed by excluding `pg_depend.deptype = 'e'` (extension-owned) rows | `PASS` after fix; re-verified after full `docker:reset` + `migrate` |
| Dev-fixtures NODE_ENV guard (6.4-6.5) | `guard.spec.ts` unit test asserting `assertNotProduction` exits 1 with a "NOT PRODUCTION DATA" banner under `NODE_ENV=production`, no-op otherwise | `seeds/guard.ts` implementation; unit test green (`npm test`); ALSO verified live: `NODE_ENV=production npx ts-node ... seed-dev-fixtures.ts` exited 1 with the banner, no rows inserted | `PASS src/database/seeds/guard.spec.ts`; live run exit code 1 |

## Work Unit Evidence

| Evidence | Value |
|---|---|
| Focused test command / result | `npm test` (root, both workspaces) — 3/3 API unit tests + 2/2 web unit tests passed |
| Runtime harness / result | Full live cycle: `docker compose up -d --wait` (healthy) → `npm run migrate` (2 migrations executed) → `npm run -w georeport-api test:e2e` (4/4 passed) → `npm run seed` (12 tipo_incidencia + 1 configuracion_duplicados, verified via `psql`) → `npm run seed:dev` (3 zona + 5 usuario, verified via `psql`) → `npm run docker:reset` + `migrate` (reproducibility) → `start:dev` and `ng serve` boot smoke tests (both started cleanly, killed by timeout as expected) |
| Rollback boundary | Everything lives in new paths: `georeport-api/`, `georeport-web/`, root `package.json`/`docker-compose.yml`/`.prettierrc.json`/`.editorconfig`/`.nvmrc`/`.gitignore`/`README.md`, plus a documentation-only edit to `db/README.md`. `git revert` of this change + `docker compose down -v` fully removes it; no production data or prior application code touched (greenfield). |

## Deviations from Design

1. **Nest CLI now scaffolds Vitest + oxlint + ESM by default** (Nest 12), not the Jest + CommonJS the design assumed from prior CLI behavior. Converted: removed `vitest.config*.ts`/`oxlint.json`, rewired `package.json`/`tsconfig.json` to CommonJS, replaced all `.js`-suffixed relative imports, added `jest.config.ts` + `test/jest-e2e.json` + `eslint.config.mjs` per Decision 2/6/7.
2. **Angular CLI now scaffolds Vitest by default too** (Angular 22 dropped Karma entirely, not just deprecated it). Removed the `test` architect target and the `vitest` devDependency; added `jest-preset-angular@17` (the first version compatible with Angular 20-22 / Jest 30) with a zoneless `setup-jest.ts` (`jest-preset-angular/setup-env/zoneless`, calling `setupZonelessTestEnv()` explicitly — the design's open question about zoneless compatibility resolved to "yes, with v17").
3. **`eslint.config.mjs` for `georeport-web` uses the unified `angular-eslint` package**, not separate `@angular-eslint/eslint-plugin` + `eslint-plugin-template`, because the per-package `configs.recommended`/`configs.tsRecommended` exports are eslintrc-format objects incompatible with ESLint 9 flat config; the unified package's `configs.tsRecommended`/`configs.templateRecommended` are the flat-config-native exports.
4. **`test/database.e2e-spec.ts` schema/trigger/function queries exclude extension-owned catalog objects** (`pg_depend.deptype = 'e'`, plus explicit `migrations`/`spatial_ref_sys` table names) — not anticipated by the design because it assumed a bare `postgis` extension; the `postgis/postgis:16-3.4` image also auto-installs `postgis_topology` and `postgis_tiger_geocoder`, which own their own tables/functions/triggers in `public`.
5. **`.env.example` could not be created**: the apply harness's file-write permission system denies writes to any `.env*` path (including `.example` suffixes), independent of file content. `database.config.ts`'s hardcoded defaults (`localhost:5433`, `georeport`/`georeport`/`georeport`) match `docker-compose.yml` exactly, so every command in this apply ran successfully without an actual `.env` file. Task 1.5's exact required content is documented in the root `README.md` and below for manual creation by a human with filesystem access:
   ```
   DB_HOST=localhost
   DB_PORT=5433
   DB_USER=georeport
   DB_PASSWORD=georeport
   DB_NAME=georeport
   ```

## Success Criteria Walk (proposal.md)

| Criterion | Met? | Evidence |
|---|---|---|
| `docker compose up` healthy, no SQL auto-mount | Yes | `Container georeport-db ... Healthy`; `docker-compose.yml` has no `docker-entrypoint-initdb.d` volume |
| `migration:run` reproduces `01-schema.sql` structure, no business triggers | Yes | `npm run migrate` clean run; `test:e2e` schema-parity + trigger-absence tests pass |
| Catalog seed loads 12 + 1 rows; fixtures separate/documented | Yes | Verified live row counts; `seed:catalog` alone leaves `zona`/`usuario` empty |
| `georeport-api` starts, Jest green | Yes | `start:dev` booted; `npm run -w georeport-api test` 3/3 passed |
| `georeport-web` starts, test runner green | Yes | `ng serve` booted; `npm run -w georeport-web test` 2/2 passed |
| ESLint + Prettier clean on both workspaces | Yes | `npm run lint` 0 errors; `npm run format:check` clean |

Only gap: `.env.example` file itself not created (permission-blocked, see Deviation 5) — its absence does not block any of the above because the code's defaults already match the compose file.

## Environment Notes

- Docker Desktop was not running at the start of this session; it was launched and became healthy before any DB-dependent work.
- npm registry connectivity was available; `npm install` at root succeeded (677 packages), with `esbuild`/`@parcel/watcher`/`lmdb`/`msgpackr-extract`/`unrs-resolver` install scripts explicitly approved (`npm install-scripts approve`) — these are standard native build tooling for Angular/esbuild, not arbitrary scripts.

## Files Changed (summary; see git status for the full list)

- Root: `package.json`, `package-lock.json`, `.nvmrc`, `.editorconfig`, `.prettierrc.json`, `.prettierignore`, `.gitignore`, `docker-compose.yml`, `README.md`
- `georeport-api/`: full NestJS scaffold (converted to CommonJS/Jest/ESLint), `src/config/database.config.ts`, `src/database/data-source.ts`, 9 entities + `enums.ts`, 3 migrations, `seeds/` (catalog + dev-fixtures + guard + data), `test/database.e2e-spec.ts`, `jest.config.ts`, `test/jest-e2e.json`, `eslint.config.mjs`
- `georeport-web/`: full Angular scaffold (Jest instead of Vitest), `jest.config.ts`, `setup-jest.ts`, `eslint.config.mjs`, `angular.json`/`package.json`/`tsconfig.spec.json` adjustments
- `db/README.md`: documentation-only edit noting root compose supersedes it for the dev loop
