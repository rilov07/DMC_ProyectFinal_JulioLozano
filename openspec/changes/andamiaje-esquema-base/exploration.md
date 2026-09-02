# Exploration: Andamiaje y esquema de base (BACKLOG.md #1)

## Current State

Greenfield repo, no application code. Existing artifacts:
- `PRD.md`, `TECH-DESIGN.md`, `Desing.md`, `adrs/0001-0013-*.md`, `BACKLOG.md`
- `db/01-schema.sql`, `db/02-seed.sql`, `db/03-consultas-prueba.sql`, `db/docker-compose.yml` (reference PostGIS model, unexecuted per `db/README.md`)
- `openspec/config.yaml`, `openspec/sdd-init.md` (already record the target stack)

## Answers to the six exploration questions

**1. Monorepo structure (Nx/Turborepo/npm workspaces/plain folders)?**
No ADR or TECH-DESIGN section names a monorepo tool. `ADR-0009` (`adrs/0009-contrato-rest-openapi.md`, lines 37-42) explicitly **rejects** "REST with a shared-types library in a monorepo" specifically because it would force adopting monorepo build tooling — it rejects the *shared-types coupling*, not necessarily a single repo with two folders. `BACKLOG.md` #1 says "Monorepo `georeport-api` + `georeport-web`" but this reads as "one repo containing both apps," consistent with the already-existing single-repo structure, not as "Nx/Turborepo with shared packages." **This is an open decision** for `sdd-propose`: whether `georeport-api`/`georeport-web` are two independent npm-managed folders (simplest, matches ADR-0009's rejection of shared build tooling) or use npm/pnpm workspaces for orchestration convenience only (without sharing DTO types, since the OpenAPI-generated client is the sync mechanism per ADR-0009).

**2. ORM/migration tool for NestJS + PostGIS?**
Not decided anywhere. `ADR-0002` (lines 46-49) and `ADR-0003` (lines 58-60) both state that PostGIS spatial queries (`ST_DWithin`, `ST_Within`/`ST_Covers`, heatmap aggregation) will be written as **explicit SQL or via the ORM's query builder, not ORM abstractions** — implying an ORM is expected for the relational parts but spatial logic stays raw SQL either way. No ORM name (TypeORM, Prisma, Knex) appears in any ADR, TECH-DESIGN, or PRD. `db/01-schema.sql` also encodes non-trivial PostgreSQL-specific business logic as triggers/functions (`fn_ingresar_reporte`, `fn_transicion_valida`, `fn_resuelto_exige_evidencia`, `fn_historial_inmutable`) — but `db/README.md` (lines 65-71) states this is a **deliberate divergence**: in the real system these rules live in the NestJS domain layer, not the database; the SQL triggers exist only to make the standalone reference model self-verifying. Migrations should port the **schema** (tables, types, indexes, constraints) from `01-schema.sql`, while the trigger-encoded business rules are candidates for reimplementation in NestJS domain services, not literal migration of the trigger functions. **Open decision**: ORM/migration tool choice, and whether to also migrate the SQL triggers verbatim as a safety net or omit them since the domain layer will own the rules.

**3. PostGIS in Docker — image, compose, env vars?**
Already fully specified and can be reused directly: `db/docker-compose.yml` uses image `postgis/postgis:16-3.4`, container `georeport-db`, DB/user/password all `georeport`, host port `5433:5432`, named volume `georeport-data`, healthcheck via `pg_isready`, and auto-runs `01-schema.sql`/`02-seed.sql` on first volume creation via `/docker-entrypoint-initdb.d/`. Since migrations will supersede the raw `01-schema.sql` bootstrap, this item should decide whether to keep the `docker-entrypoint-initdb.d` auto-run approach (fine for local/reference) or run migrations explicitly after container start (more consistent with a real migration tool) — recommendation: drop the auto-mounted SQL and instead run migrations from `georeport-api`.

**4. What does "seed de catálogo" mean?**
Per `TECH-DESIGN.md` and `db/02-seed.sql`: seed data for `tipo_incidencia` (12 rows, the PRD's closed catalog, each with `plazo_por_defecto_horas` — values are explicitly "starting values pending operational team confirmation," per `TECH-DESIGN.md` risks section and `db/README.md` line 77), and `configuracion_duplicados` (single row, conservative defaults: `radio_estricto_m=20`, `ventana_estricta_min=120`, `radio_sugerencia_m=150`, `ventana_sugerencia_min=2880`, per ADR-0012). `db/02-seed.sql` also seeds `zona` (3 placeholder rectangular polygons over Lima, explicitly **not official boundaries**) and `usuario` (5 internal accounts with placeholder password hashes). For item #1's scope, `tipo_incidencia` and `configuracion_duplicados` are safe/intended production-adjacent seed data; `zona` and `usuario` seeds are explicitly reference/test data only (item #5 depends on real zone polygons, item #2/#3 own real user provisioning) — this item should seed the catalogs but flag zona/usuario seed rows as fixtures, not production data.

**5. Testing/linting/folder conventions already decided?**
None exist yet — confirmed by `openspec/sdd-init.md` and `openspec/config.yaml` (`testing.status: no-runner-detected`, `strict_tdd: false`). No `package.json`, `nest-cli.json`, or `angular.json` exists anywhere. `openspec/config.yaml` explicitly flags: "Flag scaffolding tasks (project init, test runner setup) explicitly since none exist yet" and "Set up the test runner as part of the first apply cycle that creates georeport-api/georeport-web." Item #1 itself is responsible for establishing Jest (NestJS default) and Karma/Jest (Angular) as test runners, plus ESLint/Prettier conventions — none of which are pre-decided, so `sdd-design`/`sdd-tasks` must choose defaults (NestJS/Angular CLI conventions) rather than look them up.

**6. Open risks/pending decisions affecting this item specifically?**
- `TECH-DESIGN.md` "Riesgos técnicos abiertos" (lines 247-275): zone polygons are not yet real (blocks item #5, not #1, but the seed placeholder rectangles item #1 loads should be clearly marked as fixtures); disk-based evidence storage and embedded scheduler constrain `georeport-api` to a single instance (architectural constraint the scaffolding should respect, e.g. no premature horizontal-scaling assumptions).
- `db/README.md` states the reference SQL scripts are **unexecuted** ("Estado: sin ejecutar"), so item #1 should treat `01-schema.sql`/`03-consultas-prueba.sql` as unverified and validate them against a real PostGIS instance as part of scaffolding, not assume they are correct as-is.
- `Desing.md` "Pendientes antes de alta fidelidad" (lines 272-279) lists geographic scope, map provider (already resolved to Leaflet/OSM per ADR-0001), duplicate thresholds, and per-type SLA — none block item #1 directly, but the catalog seed values loaded here inherit these as unconfirmed.
- No monorepo tool and no ORM/migration tool decision exists (see Q1/Q2) — these are the two biggest open decisions blocking a clean `sdd-propose` for this item.

## Affected Areas (for the eventual proposal/design)

- `db/01-schema.sql`, `db/02-seed.sql`, `db/docker-compose.yml`, `db/README.md` — reference source that migrations/seeds/compose config for the real project must derive from.
- `openspec/config.yaml`, `openspec/sdd-init.md` — already declare the target stack; consistent with this exploration.
- New paths to be created by this item: `georeport-api/`, `georeport-web/` (or an `apps/`/`packages/` layout if workspaces are chosen), plus a root or `db/`-adjacent `docker-compose.yml` for local dev.

## Approaches

1. **Plain two-folder repo, npm-managed independently per app, no shared-types package** — matches ADR-0009's explicit rejection of shared-types monorepo coupling; OpenAPI-generated client is the only cross-boundary contract.
   - Pros: simplest, fewest tools to learn, directly aligned with an accepted ADR's stated preference; matches "one person, one course deadline" constraint from ADR-0001/0002.
   - Cons: no single `npm install`/script runner across both apps; slightly more manual CI/dev-script duplication.
   - Effort: Low

2. **npm/pnpm workspaces (no Nx/Turborepo) — root `package.json` orchestrates both apps' scripts, still no shared-types package** — convenience layer only, does not reintroduce what ADR-0009 rejected.
   - Pros: single `npm install`, unified lint/test scripts, still respects the ADR-0009 boundary since no DTOs are shared as code.
   - Cons: adds workspace configuration surface; must confirm this doesn't count as "the monorepo with shared build config" ADR-0009 rejected.
   - Effort: Low-Medium

3. **Nx or Turborepo monorepo** — full build-graph tooling.
   - Pros: caching, generators, task graphs — useful if the project grows.
   - Cons: directly the kind of "monorepo with its own build configuration" ADR-0009 cites as a reason it rejected the shared-types alternative; disproportionate for a one-person, course-deadline project; no ADR or TECH-DESIGN mention supports it.
   - Effort: Medium-High

**ORM approaches** (parallel, independent decision):
- **TypeORM** — first-class NestJS integration (`@nestjs/typeorm`), built-in migration CLI, widely used with NestJS; PostGIS columns handled via raw column types/custom transformers since ORM lacks native `geography` support (consistent with ADR-0002/0003's "raw SQL for spatial" stance).
- **Prisma** — stronger typing/DX, but weaker PostGIS support (community extensions needed for `geography`/`GiST`), and its migration model is less flexible for hand-written trigger/function migrations that `01-schema.sql` currently uses.
- **Raw SQL migration runner (e.g. `node-pg-migrate`) with no ORM** — keeps everything as explicit SQL, closest to the existing `db/01-schema.sql` reference; loses ORM convenience for the non-spatial CRUD majority of the schema.

## Recommendation

- Monorepo structure: **Approach 2 (npm/pnpm workspaces without shared-types package)** — balances one-person velocity with staying inside what ADR-0009 already ruled out (a shared-types monorepo). Should be explicitly confirmed in `sdd-propose` since no ADR settles it.
- ORM/migrations: **TypeORM**, given first-class NestJS integration and migration tooling, with spatial columns/queries handled via raw SQL per ADR-0002/0003 (already the documented pattern for spatial queries regardless of ORM choice). Genuine open decision to confirm in `sdd-propose`, not a settled fact.
- Docker/PostGIS: reuse `db/docker-compose.yml` as-is (image, port 5433, healthcheck) but stop auto-mounting `01-schema.sql`/`02-seed.sql` into `docker-entrypoint-initdb.d`; instead run TypeORM migrations and a seed script from `georeport-api` after the container is healthy.
- Seed: port `tipo_incidencia` and `configuracion_duplicados` from `db/02-seed.sql` as the catalog seed; keep `zona`/`usuario` seed rows as clearly-labeled fixture/dev-only data, not production seed.

## Risks

- No ADR settles monorepo tooling or ORM choice — proceeding without confirming these in `sdd-propose` risks contradicting ADR-0009's explicit rejection of shared-types monorepo coupling.
- `db/01-schema.sql`/`03-consultas-prueba.sql` are unexecuted/unverified against a real PostGIS instance; migrations derived from them should be validated, not assumed correct.
- The reference schema encodes domain rules as Postgres triggers/functions that `db/README.md` explicitly says do NOT belong in the real system (they belong in NestJS domain services) — a naive "port the whole schema" instruction could accidentally migrate triggers that duplicate/conflict with future NestJS domain logic (items #10-#14).
- Zone polygons and per-type SLA seed values are explicitly placeholder/unconfirmed (open PRD/TECH-DESIGN risks) — seeding them without a "not production data" flag could mislead later items (#5, #16).
- `strict_tdd` is `false` because no test runner exists yet; this item is the one responsible for establishing Jest/Karma test runners, which is easy to under-scope if not called out explicitly in tasks.

## Ready for Proposal

Yes, with two flagged open decisions to resolve first (or explicitly defer) in `sdd-propose`: (1) monorepo tooling (recommend npm/pnpm workspaces, no Nx/Turborepo, no shared-types package per ADR-0009), and (2) ORM/migration tool (recommend TypeORM). Everything else (Docker/PostGIS setup, seed scope, testing/linting conventions, schema-vs-trigger migration boundary) has enough source material in `TECH-DESIGN.md`, the ADRs, and `db/` to proceed directly.

---

**Status**: done (persisted by orchestrator; sdd-explore sub-agent had no Write tool available in this session)
**Executive Summary**: Explored BACKLOG.md item #1 (scaffolding + base schema) against PRD/TECH-DESIGN/ADRs/db reference model; PostGIS Docker setup, seed scope, and testing gaps are well-documented, but monorepo tooling and ORM/migration tool are genuinely undecided and must be confirmed in `sdd-propose`.
**Artifacts**: `openspec/changes/andamiaje-esquema-base/exploration.md`
**Next Recommended**: sdd-propose
**Risks**: (1) monorepo tooling undecided, risks conflicting with ADR-0009's rejection of shared-types monorepo coupling; (2) ORM/migration tool undecided; (3) `db/01-schema.sql` is unexecuted/unverified; (4) reference schema mixes domain-rule triggers that should NOT be ported verbatim per `db/README.md`; (5) zone/user seed rows are placeholder fixtures, not production data; (6) test runner setup has zero prior decisions and must be scoped explicitly in tasks.
**Skill Resolution**: none — no `## Skills to load before work` block or skill registry was found; proceeded with `sdd-explore` SKILL.md and `sdd-phase-common.md` only.

## Key Learnings

1. ADR-0009 explicitly rejects a shared-types monorepo pattern, which conflicts with BACKLOG.md item #1 casually calling the target layout a "monorepo."
2. No ADR, PRD, or TECH-DESIGN document names a specific ORM or migration tool for NestJS plus PostGIS.
3. The reference `db/01-schema.sql` encodes domain business rules as PostgreSQL triggers that `db/README.md` says must NOT be ported into the real NestJS-based system.
4. The reference SQL scripts under `db/` are explicitly unexecuted and unverified against a real PostGIS instance.
5. Zone polygons and per-type escalation SLAs seeded in `db/02-seed.sql` are documented as placeholder values pending real operational data.
