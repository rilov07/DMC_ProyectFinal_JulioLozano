import dataSource from '../data-source';
import { USUARIO_FIXTURES, ZONA_FIXTURES } from './data/dev-fixtures';
import { assertNotProduction } from './guard';

async function seedDevFixtures(): Promise<void> {
  assertNotProduction();

  await dataSource.initialize();

  for (const zona of ZONA_FIXTURES) {
    await dataSource.query(
      `INSERT INTO zona (nombre, poligono)
       VALUES ($1, ST_GeogFromText($2))
       ON CONFLICT (nombre) DO NOTHING`,
      [zona.nombre, zona.poligonoWkt],
    );
  }

  for (const usuario of USUARIO_FIXTURES) {
    await dataSource.query(
      `INSERT INTO usuario (nombre, email, hash_password, rol)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (email) DO NOTHING`,
      [usuario.nombre, usuario.email, usuario.hashPassword, usuario.rol],
    );
  }

  await dataSource.destroy();
  console.log(
    `\n*** NOT PRODUCTION DATA ***\nseed:dev-fixtures — ${ZONA_FIXTURES.length} zona + ${USUARIO_FIXTURES.length} usuario placeholder rows ensured.\n`,
  );
}

seedDevFixtures().catch((error: unknown) => {
  console.error('seed:dev-fixtures failed:', error);
  process.exit(1);
});
