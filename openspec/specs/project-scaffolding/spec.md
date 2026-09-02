# Project Scaffolding Specification

## Purpose

Establish the executable monorepo skeleton for GeoReport Vial: npm/pnpm workspaces orchestrating `georeport-api` (NestJS) and `georeport-web` (Angular), each with a working test runner and lint/format tooling, so later backlog items build on a real foundation instead of an empty repo.

## Requirements

### Requirement: Single-Command Dependency Install

The root workspace MUST allow installing dependencies for both `georeport-api` and `georeport-web` with a single command executed from the repository root.

#### Scenario: Fresh clone installs all workspace dependencies

- GIVEN a fresh clone of the repository with no `node_modules` present
- WHEN a developer runs the root install command (e.g. `npm install`)
- THEN dependencies for both `georeport-api` and `georeport-web` are installed
- AND no separate per-app install command is required

### Requirement: No Shared-Types Package

The workspace MUST NOT introduce a shared package of DTO/type definitions between `georeport-api` and `georeport-web`.

#### Scenario: Workspace has exactly two app packages

- GIVEN the root `package.json` workspaces configuration
- WHEN the workspace member list is inspected
- THEN it contains only `georeport-api` and `georeport-web`
- AND no shared-types or shared-DTO package exists

### Requirement: API Scaffold Starts and Tests Run

`georeport-api` MUST start in development mode and MUST run its test suite via Jest, producing a passing result on the initial scaffold.

#### Scenario: API dev server starts

- GIVEN `georeport-api` dependencies are installed
- WHEN the API start command is run (e.g. `npm run -w georeport-api start:dev`)
- THEN the NestJS application starts without error

#### Scenario: API test suite runs green

- GIVEN `georeport-api` dependencies are installed
- WHEN the API test command is run (e.g. `npm run -w georeport-api test`)
- THEN Jest executes at least one test
- AND all executed tests pass

### Requirement: Web Scaffold Starts and Tests Run

`georeport-web` MUST start in development mode and MUST run its test suite via the chosen runner (Karma or Jest), producing a passing result on the initial scaffold.

#### Scenario: Web dev server starts

- GIVEN `georeport-web` dependencies are installed
- WHEN the web start command is run (e.g. `npm run -w georeport-web start`)
- THEN the Angular application starts without error

#### Scenario: Web test suite runs green

- GIVEN `georeport-web` dependencies are installed
- WHEN the web test command is run (e.g. `npm run -w georeport-web test`)
- THEN the configured runner executes at least one test
- AND all executed tests pass

### Requirement: Lint and Format Tooling

Both `georeport-api` and `georeport-web` MUST have ESLint and Prettier configured and runnable, and MUST report zero errors on the unmodified scaffold.

#### Scenario: Lint runs clean on scaffold

- GIVEN the initial scaffold of both apps, unmodified
- WHEN the lint command is run for each workspace (e.g. `npm run lint`)
- THEN ESLint completes with zero errors

### Requirement: Scaffolding Excludes Business Behavior

The scaffold MUST NOT include authentication, business REST endpoints/controllers, or functional UI screens beyond the CLI-generated defaults.

#### Scenario: No business endpoints exist yet

- GIVEN the scaffolded `georeport-api`
- WHEN its controllers are inspected
- THEN only CLI-generated default routes exist (e.g. health/root)
- AND no authentication, incident, report, or zone endpoints are present

#### Scenario: No functional UI exists yet

- GIVEN the scaffolded `georeport-web`
- WHEN its routes/components are inspected
- THEN only the CLI-generated default shell exists
- AND no business screens (map, incident list, validation queue) are present
