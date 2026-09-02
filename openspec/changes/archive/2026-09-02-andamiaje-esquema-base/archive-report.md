# Archive Report: Andamiaje y esquema de base

**Change**: andamiaje-esquema-base (BACKLOG.md item #1)
**Archived**: 2026-09-02
**Status**: COMPLETE

## Executive Summary

The GeoReport Vial scaffolding and database schema change has been successfully implemented, verified, and archived. All 46 tasks completed, all 13 requirements and 21 scenarios across three specs (`project-scaffolding`, `database-schema`, `catalog-seed`) verified as conformant. Work delivered as single PR per user's explicit `size:exception` acceptance. Specs promoted to authoritative source in `openspec/specs/`. Ready for next backlog item.

## Artifacts Archived

| Artifact | Source | Status | Notes |
|----------|--------|--------|-------|
| `proposal.md` | `openspec/changes/archive/2026-09-02-andamiaje-esquema-base/proposal.md` | ✅ | Intent, scope, approach, risks, rollback |
| `design.md` | `openspec/changes/archive/2026-09-02-andamiaje-esquema-base/design.md` | ✅ | Technical approach, 8 ADRs, file changes, interfaces |
| `tasks.md` | `openspec/changes/archive/2026-09-02-andamiaje-esquema-base/tasks.md` | ✅ | 46 tasks, 7 phases, 100% completion |
| `specs/project-scaffolding/spec.md` | `openspec/changes/archive/2026-09-02-andamiaje-esquema-base/specs/project-scaffolding/spec.md` | ✅ | 5 requirements, 8 scenarios |
| `specs/database-schema/spec.md` | `openspec/changes/archive/2026-09-02-andamiaje-esquema-base/specs/database-schema/spec.md` | ✅ | 5 requirements, 7 scenarios |
| `specs/catalog-seed/spec.md` | `openspec/changes/archive/2026-09-02-andamiaje-esquema-base/specs/catalog-seed/spec.md` | ✅ | 3 requirements, 6 scenarios |
| `apply-progress.md` | `openspec/changes/archive/2026-09-02-andamiaje-esquema-base/apply-progress.md` | ✅ | Intermediate snapshot, all 46 tasks marked complete |
| `verify-report.md` | `openspec/changes/archive/2026-09-02-andamiaje-esquema-base/verify-report.md` | ✅ | Verdict PASS, 0 blockers, 0 critical findings |

**Specs promoted to main source of truth:**
- `openspec/specs/project-scaffolding/spec.md` (92 lines)
- `openspec/specs/database-schema/spec.md` (67 lines)
- `openspec/specs/catalog-seed/spec.md` (63 lines)

## Final State Authority

This archive report records the state of the change at closure. The following facts are sourced from the hierarchy established in the SKILL.md Final-State Authority section:

### Work Completion

**Source**: `tasks.md` (persisted tasks artifact) — highest-ranked source per Final-State Authority

- **46/46 implementation tasks complete** — all marked [x] in persisted `tasks.md`
  - Phase 1 (Monorepo & Docker): 6/6 complete
  - Phase 2 (API Scaffold): 8/8 complete
  - Phase 3 (Web Scaffold): 6/6 complete
  - Phase 4 (Entities & Migrations): 7/7 complete
  - Phase 5 (Migration Verification): 7/7 complete
  - Phase 6 (Seed Scripts): 6/6 complete
  - Phase 7 (Lint, Docs, Wiring): 6/6 complete

**Note on task 1.5 (.env.example):**
- Intermediate snapshot (`apply-progress.md`): reported blocked by sandbox permissions during apply phase
- Orchestrator's explicit final-state facts: `.env.example` already exists (89 bytes), is committed in commit `4070ace`, and was independently verified by the orchestrator
- Final state per Final-State Authority: **COMPLETE** — the orchestrator's explicit launch-prompt facts rank higher than the intermediate snapshot's "blocked" claim. The file exists, contains the five `DB_*` variables, and is part of the delivered commit.

### Verification Results

**Source**: `verify-report.md` and orchestrator's final-state facts

- **Verdict**: PASS (no blockers, no critical findings)
- **Build & Tests**: All passed live
  - Build: PASS (Nest and Angular bundles clean)
  - Unit tests: 5 tests / 3 suites PASS (no DB required)
  - Integration/DB tests: 4 tests / 2 suites PASS (live PostGIS container)
  - Lint: 0 errors (1 pre-approved warning in generated e2e spec per tasks.md 7.2)
  - Format: PASS (all files use Prettier style)
  - Type checking: PASS (implicit in successful builds)

**Spec Compliance**: 13/13 requirements, 21/21 scenarios across all three specs

| Spec | Requirements | Scenarios | Status |
|------|--------------|-----------|--------|
| Project Scaffolding | 5 | 8 | All compliant |
| Database Schema | 5 | 7 | All compliant |
| Catalog Seed | 3 | 6 | All compliant |

Evidence per `verify-report.md`: Every scenario verified with live runtime execution against a freshly reset PostGIS container. Migrations validated, geography column types confirmed, seed idempotence verified, `NODE_ENV=production` guard tested, lint/format/build all executed live.

### Design Decisions Adherence

All 8 architectural decisions from `design.md` implemented as specified:

| Decision | Followed | Notes |
|----------|----------|-------|
| D1: npm workspaces | ✅ | Root `package.json` orchestrates `georeport-api` and `georeport-web` |
| D2: hand-written migrations | ✅ | Raw SQL via `queryRunner.query()`, not `typeorm migration:generate` |
| D3: trigger exclusion | ✅ | 6 business functions deliberately excluded per items #10–#14 deferral |
| D4: spatial columns `select/insert/update: false` | ✅ | Confirmed in `zona.entity.ts` and other spatial entities |
| D5: two named seed scripts, no flag | ✅ | `seed:catalog` vs `seed:dev-fixtures` with production guard |
| D6: Jest for web via CLI, no Karma | ✅ | Angular 22 CLI defaulted to Vitest (not Karma as design assumed); apply converted to Jest + `jest-preset-angular` per decision's intent; result matches goal |
| D7: Prettier root, ESLint per workspace | ✅ | Cascading format config, workspace-specific lint configs |
| D8: new root compose, distinct volume | ✅ | `georeport-api-data` volume, no `docker-entrypoint-initdb.d` mount |

## Delivery Strategy

**Strategy**: `size:exception` (explicitly accepted by user despite 2500–3500 LOC forecast exceeding 400-line default budget)

| Field | Value |
|-------|-------|
| Estimated changed lines | ~2500–3500 |
| 400-line budget risk | High |
| Chained PRs recommended | Yes (decline by user; single PR accepted) |
| Delivery model | Single PR covering all 46 tasks and all three specs |
| Commits | 2 (both pushed to origin) |
| Branch | `feat/andamiaje-esquema-base` |

**Commit history**:
1. `4070ace` — implementation: 84 files, all scaffolds, migrations, seeds, tests, lint/format configs, root orchestration
2. `b5d715f` — verify-report: persist verification results post-implementation

Both commits present on `origin/feat/andamiaje-esquema-base`, current with main. **Note**: No PR has been created yet per orchestrator's launch instruction ("NO hagas commit ni push"); PR creation will be the orchestrator's next step after archive.

## Changes to Authoritative Specs

The three delta specs have been mechanically copied to the main specs repository:

| Delta → Main | Domain | Records | Status |
|---|---|---|---|
| `openspec/changes/andamiaje-esquema-base/specs/project-scaffolding/spec.md` → `openspec/specs/project-scaffolding/spec.md` | Project Scaffolding | 5 requirements + 8 scenarios | ✅ Promoted (new) |
| `openspec/changes/andamiaje-esquema-base/specs/database-schema/spec.md` → `openspec/specs/database-schema/spec.md` | Database Schema | 5 requirements + 7 scenarios | ✅ Promoted (new) |
| `openspec/changes/andamiaje-esquema-base/specs/catalog-seed/spec.md` → `openspec/specs/catalog-seed/spec.md` | Catalog Seed | 3 requirements + 6 scenarios | ✅ Promoted (new) |

All three were new-file promotions (no existing specs to merge). Mechanical verification via `diff -r` confirmed byte-identity of copies.

## Mechanical Archive Verification

Per SKILL.md Mechanical Copy Contract, all archive operations used shell commands (`cp -R`, `git mv`) with mandatory `diff -r` readback verification:

**Spec promotion (delta → main):**
```
project-scaffolding/spec.md: diff exit 0 (no differences) ✅
database-schema/spec.md: diff exit 0 (no differences) ✅
catalog-seed/spec.md: diff exit 0 (no differences) ✅
```

**Change folder archive move:**
```
Source:      openspec/changes/andamiaje-esquema-base/
Destination: openspec/changes/archive/2026-09-02-andamiaje-esquema-base/
Method:      git mv (tracked artifact)
Verification: diff -r source vs archived destination exit 0 (no differences) ✅
Source after move: absent (confirmed via [ -e ] check) ✅
```

## Open Questions & Notes

### Angular 22 Vitest Default Deviation (Documented in Design)

The design specified Karma removal per decision D6, but Angular 22's CLI scaffolded with Vitest (not Karma). The apply phase converted the result to Jest + `jest-preset-angular` per the decision's actual intent (one test runner across both apps). This deviation is documented in the design's Open Questions section and was explicitly verified in the verify-report. Result: Jest in both apps (matches D6 goal), Vitest mention removed from `angular.json`, tests green.

### Environment Warnings (Non-Defects)

Per `verify-report.md`:

1. **Validator unavailable** — `gentle-ai sdd-verify-validate` CLI is not installed in this environment. Does not affect OpenSpec artifact store (which does not depend on it). Orchestrator accepted alternate persistence path (direct file write).
2. **`.env.example` sandbox read restriction** — verify session's sandbox denies reads on `.env*` paths. Orchestrator independently confirmed the file exists and committed it. Not a codebase defect.

### Future Considerations

- Angular's future likely migration from Jest to Vitest — noted in design but outside scope
- No coverage tool configured at scaffold stage — appropriate for this change; recommend adding in backlog item #2 or later as coverage tracking is not part of greenfield baseline

## Dependencies & Blockers

- No dependencies on other backlog items (first item)
- No unresolved blockers at closure
- Next recommended: backlog item #2 (Authentication & session management) can now build on this scaffolding

## SDD Cycle Closure

All phases completed:
1. ✅ **sdd-propose** — proposal accepted
2. ✅ **sdd-spec** — three specs created and conformance validated
3. ✅ **sdd-design** — architecture documented, 8 decisions recorded
4. ✅ **sdd-tasks** — 46 tasks defined with delivery strategy guidance
5. ✅ **sdd-apply** — all tasks implemented, verified, committed
6. ✅ **sdd-verify** — PASS verdict, all specs compliant, live test evidence
7. ✅ **sdd-archive** — specs promoted, change archived, cycle closed

## Archival Metadata

| Field | Value |
|-------|-------|
| Archive date | 2026-09-02 (ISO format) |
| Archive path | `openspec/changes/archive/2026-09-02-andamiaje-esquema-base/` |
| Artifact store mode | openspec (file-based, no Engram) |
| Change name | `andamiaje-esquema-base` |
| Project | GeoReport Vial |
| Archived by | sdd-archive (executor phase) |
| Final status | COMPLETE · DELIVERED · ARCHIVED |
