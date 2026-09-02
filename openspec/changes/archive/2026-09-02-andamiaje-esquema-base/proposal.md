# Proposal: Andamiaje y esquema de base

## Intent

GeoReport Vial es un repo greenfield sin código de aplicación: no existe `package.json`, `nest-cli.json`, `angular.json` ni test runner. Este cambio (BACKLOG.md ítem #1, sin dependencias previas) crea el andamiaje mínimo ejecutable — dos aplicaciones, base de datos PostGIS en Docker, migraciones versionadas y seed de catálogo — para que los ítems #2 en adelante (auth, dominio, endpoints) tengan una base real sobre la cual construir en vez de partir de cero cada vez.

## Scope

### In Scope
- Monorepo con npm/pnpm workspaces: `package.json` raíz orquesta `georeport-api/` (NestJS) y `georeport-web/` (Angular), sin librería de tipos compartida (respeta el rechazo de ADR-0009 a monorepo con shared-types; el contrato entre apps sigue siendo OpenAPI).
- `georeport-api` scaffolded con NestJS CLI, TypeORM (`@nestjs/typeorm`) configurado contra PostGIS, y su propio CLI de migraciones.
- Migraciones TypeORM que portan la ESTRUCTURA de `db/01-schema.sql` (tablas, tipos, índices, constraints) — sin los triggers/funciones de negocio (`fn_ingresar_reporte`, `fn_transicion_valida`, `fn_resuelto_exige_evidencia`, `fn_historial_inmutable`), que quedan diferidos a la capa de dominio de NestJS (ítems #10-#14).
- Seed de catálogo real ejecutado vía script desde `georeport-api`: `tipo_incidencia` (12 filas) y `configuracion_duplicados` (1 fila, defaults de ADR-0012).
- Fixtures de desarrollo/test explícitamente marcadas como no-producción: `zona` (3 polígonos placeholder) y `usuario` (5 cuentas placeholder).
- `docker-compose.yml` reutilizando `db/docker-compose.yml` (imagen `postgis/postgis:16-3.4`, puerto 5433) SIN auto-montar SQL en `docker-entrypoint-initdb.d`; migraciones corren desde `georeport-api` tras el healthcheck.
- `georeport-web` scaffolded con Angular CLI (standalone/signals per TECH-DESIGN.md), sin lógica de negocio todavía.
- Test runners funcionando desde cero: Jest en `georeport-api`, Karma o Jest en `georeport-web`; ESLint + Prettier en ambos.

### Out of Scope
- Autenticación real, JWT, cookies httpOnly (ítem #2).
- Cualquier endpoint REST de negocio, controladores, servicios de dominio (ítems #3+).
- Reglas de negocio (transiciones de estado, detección de duplicados, evidencia obligatoria) — deliberadamente NO se portan como triggers SQL; van a NestJS en ítems futuros.
- Polígonos de zona reales y aprovisionamiento real de usuarios (ítems #2, #5).
- CI/CD, despliegue, infraestructura fuera de Docker local.
- Cualquier UI/pantalla funcional en `georeport-web` más allá del scaffold base.

## Capabilities

### New Capabilities
- `project-scaffolding`: estructura de monorepo (workspaces), scaffolds de NestJS y Angular, configuración de linting/formatting y test runners.
- `database-schema`: esquema relacional/PostGIS gestionado por migraciones TypeORM, derivado de `db/01-schema.sql` sin los triggers de negocio.
- `catalog-seed`: carga de datos de catálogo (`tipo_incidencia`, `configuracion_duplicados`) y fixtures de desarrollo (`zona`, `usuario`) claramente diferenciadas.

### Modified Capabilities
- None (no hay specs previas en `openspec/specs/`; este es el primer ítem).

## Approach

1. **Monorepo**: `package.json` raíz con `workspaces: ["georeport-api", "georeport-web"]`; scripts raíz delegan a cada workspace (`npm run -w georeport-api ...`). Sin paquete de tipos compartidos.
2. **API**: scaffold con `@nestjs/cli`; instalar `@nestjs/typeorm`, `typeorm`, `pg`. Definir entidades TypeORM para las tablas no espaciales y usar tipos de columna raw/`geography` vía `columnType: 'geography'` con transformers, consistente con ADR-0002/0003 (spatial queries en SQL crudo, no vía ORM). Generar migraciones desde las entidades, validadas manualmente contra `db/01-schema.sql`.
3. **DB/Docker**: reutilizar `db/docker-compose.yml` quitando el volumen `docker-entrypoint-initdb.d`; agregar script `npm run -w georeport-api migration:run` y `seed:run` documentados en README.
4. **Seed**: script TypeORM (`data-source` seed runner o comando Nest) que inserta `tipo_incidencia` y `configuracion_duplicados` desde datos portados de `db/02-seed.sql`; script separado o flag explícito para `zona`/`usuario` fixtures, documentado como no-producción.
5. **Web**: scaffold con `@angular/cli` (standalone components, signals), sin rutas de negocio.
6. **Testing/Linting**: Jest config por defecto de NestJS CLI; Karma (default Angular CLI) o Jest si se prefiere unificar — decisión de implementación en `sdd-design`/`sdd-tasks`. ESLint + Prettier en ambos workspaces con configs compartidas a nivel raíz donde sea práctico.

## Affected Areas

| Area | Impact | Description |
|------|--------|--------------|
| `package.json` (raíz) | New | Workspaces npm/pnpm orquestando ambas apps |
| `georeport-api/` | New | Scaffold NestJS, TypeORM, migraciones, seed scripts, Jest, ESLint |
| `georeport-web/` | New | Scaffold Angular, test runner, ESLint |
| `docker-compose.yml` (raíz o adaptado de `db/`) | New | PostGIS local sin auto-init SQL |
| `db/01-schema.sql`, `db/02-seed.sql` | Reference only | Fuente para migraciones/seed; no se ejecutan directamente en el flujo real |
| `openspec/specs/project-scaffolding/`, `.../database-schema/`, `.../catalog-seed/` | New | Specs a crear en fase `sdd-spec` |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| `db/01-schema.sql` está sin ejecutar/verificar contra PostGIS real | Medium | Validar cada migración levantando el contenedor Docker antes de dar el ítem por cerrado |
| Confundir triggers de negocio con estructura pura al portar el schema | Medium | Checklist explícito en tasks: listar tablas/tipos/índices a portar vs. funciones/triggers a excluir |
| Seed de fixtures (`zona`/`usuario`) usado accidentalmente como dato de producción | Low | Nombrar el script de fixtures por separado del seed de catálogo y documentarlo en README |
| Elección de test runner en `georeport-web` (Karma vs Jest) sin precedente | Low | Confirmar en `sdd-design`; cualquiera de las dos opciones es válida y reversible en este estadio |

## Rollback Plan

Todo lo creado por este ítem vive en carpetas nuevas (`georeport-api/`, `georeport-web/`, `package.json` raíz, `docker-compose.yml`) sin tocar código de aplicación preexistente. Rollback = `git revert` del commit/PR de este cambio y `docker compose down -v` para eliminar el volumen de datos local. No hay migraciones de datos de producción en juego (greenfield).

## Dependencies

- Ninguna dependencia de otros ítems del backlog (es el primer ítem).
- Requiere Docker/Docker Compose disponible en el entorno de desarrollo.
- Requiere Node.js/npm (versión a fijar en `sdd-design` o `.nvmrc`).

## Success Criteria

- [ ] `docker compose up` levanta PostGIS (`postgis/postgis:16-3.4`) sano (healthcheck en verde) sin montar SQL crudo en `docker-entrypoint-initdb.d`.
- [ ] `npm run -w georeport-api migration:run` (o equivalente) aplica las migraciones TypeORM limpio sobre el contenedor recién creado, reproduciendo la estructura de `db/01-schema.sql` (tablas, tipos, índices, constraints) sin los triggers de negocio.
- [ ] El seed de catálogo carga `tipo_incidencia` (12 filas) y `configuracion_duplicados` (1 fila) correctamente; un script/flag separado y documentado carga las fixtures `zona`/`usuario` marcadas como no-producción.
- [ ] `georeport-api` arranca (`npm run -w georeport-api start:dev`) y su test runner (Jest) corre al menos un test trivial en verde.
- [ ] `georeport-web` arranca (`npm run -w georeport-web start`) y su test runner (Karma o Jest) corre al menos un test trivial en verde.
- [ ] ESLint + Prettier configurados y ejecutables (`npm run lint`) en ambos workspaces sin errores sobre el scaffold inicial.
