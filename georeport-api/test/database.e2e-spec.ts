import { DataSource } from 'typeorm';
import { buildDataSourceOptions } from '../src/config/database.config';

// Integration project (test:e2e). Requires `npm run db:reset` (or
// `docker:up` + `migrate`) against a live PostGIS container beforehand —
// see package.json scripts and Design: Andamiaje y esquema de base,
// Testing Strategy.
//
// RED/GREEN pairing (Design.md, Testing Strategy + tasks.md Phase 5):
//   5.1/5.2 -> "reproduces the reference table/enum structure"
//   5.3/5.4 -> "constraints and indexes match the reference structure"
//   5.5/5.6 -> "no business trigger or function is migrated"
describe('database schema (e2e)', () => {
  let dataSource: DataSource;

  beforeAll(async () => {
    dataSource = new DataSource(buildDataSourceOptions());
    await dataSource.initialize();
  });

  afterAll(async () => {
    await dataSource.destroy();
  });

  it('reproduces the reference table/enum structure', async () => {
    const tables: Array<{ table_name: string }> = await dataSource.query(`
      SELECT table_name FROM information_schema.tables
      WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
        AND table_name NOT IN ('migrations', 'spatial_ref_sys')
    `);
    const tableNames = tables.map((t) => t.table_name).sort();

    expect(tableNames).toEqual(
      [
        'configuracion_duplicados',
        'evidencia',
        'historial_incidencia',
        'incidencia',
        'notificacion',
        'reporte',
        'tipo_incidencia',
        'usuario',
        'zona',
      ].sort(),
    );

    const enums: Array<{ typname: string }> = await dataSource.query(`
      SELECT typname FROM pg_type
      WHERE typtype = 'e' AND typnamespace = 'public'::regnamespace
    `);
    const enumNames = enums.map((e) => e.typname).sort();

    expect(enumNames).toEqual(
      [
        'actor_tipo',
        'causal_descarte',
        'estado_carga',
        'estado_incidencia',
        'prioridad',
        'rol_usuario',
        'tipo_evidencia',
        'tipo_notificacion',
      ].sort(),
    );
  });

  it('matches the reference CHECK constraints and GiST/partial indexes', async () => {
    const checks: Array<{ conname: string }> = await dataSource.query(`
      SELECT conname FROM pg_constraint
      WHERE contype = 'c' AND connamespace = 'public'::regnamespace
    `);
    const checkNames = checks.map((c) => c.conname);

    for (const name of [
      'chk_descarte_exige_causal',
      'chk_asignacion_completa',
      'chk_resuelta_en_coherente',
      'chk_evidencia_dueno_unico',
      'chk_evidencia_tipo_coherente',
      'chk_actor_coherente',
    ]) {
      expect(checkNames).toContain(name);
    }

    const gistIndexes: Array<{ indexname: string }> = await dataSource.query(`
      SELECT indexname FROM pg_indexes
      WHERE schemaname = 'public' AND indexdef ILIKE '%USING gist%'
    `);
    const gistNames = gistIndexes.map((i) => i.indexname).sort();

    expect(gistNames).toEqual(
      ['idx_zona_poligono', 'idx_incidencia_ubicacion', 'idx_reporte_ubicacion'].sort(),
    );
  });

  it('does not migrate any business trigger or function', async () => {
    // Excludes functions owned by an extension (PostGIS installs hundreds of
    // its own into public); only USER-defined functions must be zero.
    const functions: Array<{ proname: string }> = await dataSource.query(`
      SELECT p.proname FROM pg_proc p
      WHERE p.pronamespace = 'public'::regnamespace
        AND NOT EXISTS (
          SELECT 1 FROM pg_depend d WHERE d.objid = p.oid AND d.deptype = 'e'
        )
    `);
    expect(functions).toHaveLength(0);

    // Excludes triggers whose underlying table belongs to an extension
    // (PostGIS/postgis_topology ship their own, e.g. on topology.layer);
    // only USER-defined triggers on OUR tables must be zero.
    const triggers: Array<{ tgname: string }> = await dataSource.query(`
      SELECT t.tgname FROM pg_trigger t
      WHERE NOT t.tgisinternal
        AND NOT EXISTS (
          SELECT 1 FROM pg_depend d WHERE d.objid = t.tgrelid AND d.deptype = 'e'
        )
    `);
    expect(triggers).toHaveLength(0);
  });
});
