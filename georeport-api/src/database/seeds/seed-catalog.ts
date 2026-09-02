import dataSource from '../data-source';
import { TIPO_INCIDENCIA_CATALOG } from './data/tipo-incidencia.catalog';

// Idempotent: safe to run in any environment, including production
// (Design: Andamiaje y esquema de base, Decision 5 / Interfaces).
async function seedCatalog(): Promise<void> {
  await dataSource.initialize();

  for (const item of TIPO_INCIDENCIA_CATALOG) {
    await dataSource.query(
      `INSERT INTO tipo_incidencia (nombre, plazo_por_defecto_horas)
       VALUES ($1, $2)
       ON CONFLICT (nombre) DO NOTHING`,
      [item.nombre, item.plazoPorDefectoHoras],
    );
  }

  // ADR-0012 defaults; the table's own column DEFAULTs already match them.
  await dataSource.query(
    `INSERT INTO configuracion_duplicados (id) VALUES (1) ON CONFLICT DO NOTHING`,
  );

  await dataSource.destroy();
  console.log(
    `seed:catalog — ${TIPO_INCIDENCIA_CATALOG.length} tipo_incidencia rows ensured, configuracion_duplicados ensured.`,
  );
}

seedCatalog().catch((error: unknown) => {
  console.error('seed:catalog failed:', error);
  process.exit(1);
});
