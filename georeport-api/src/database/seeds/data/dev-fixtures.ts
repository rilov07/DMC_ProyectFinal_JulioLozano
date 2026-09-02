// NOT PRODUCTION DATA — placeholder rectangles/accounts for local
// development and integration tests only. Ported from db/02-seed.sql
// (read-only reference); see db/README.md and Design: Andamiaje y esquema
// de base, Decision 5.
export interface ZonaFixture {
  nombre: string;
  poligonoWkt: string;
}

export const ZONA_FIXTURES: ZonaFixture[] = [
  {
    nombre: 'Miraflores',
    poligonoWkt:
      'POLYGON((-77.060 -12.140, -77.010 -12.140, -77.010 -12.100, -77.060 -12.100, -77.060 -12.140))',
  },
  {
    nombre: 'San Isidro',
    poligonoWkt:
      'POLYGON((-77.060 -12.100, -77.010 -12.100, -77.010 -12.070, -77.060 -12.070, -77.060 -12.100))',
  },
  {
    nombre: 'Surco',
    poligonoWkt:
      'POLYGON((-77.010 -12.160, -76.960 -12.160, -76.960 -12.100, -77.010 -12.100, -77.010 -12.160))',
  },
];

export interface UsuarioFixture {
  nombre: string;
  email: string;
  hashPassword: string;
  rol: 'VALIDADOR' | 'RESPONSABLE' | 'SUPERVISOR' | 'ADMIN';
}

export const USUARIO_FIXTURES: UsuarioFixture[] = [
  {
    nombre: 'Ana Quispe',
    email: 'ana.quispe@muni.gob.pe',
    hashPassword: '$2b$12$PLACEHOLDER',
    rol: 'VALIDADOR',
  },
  {
    nombre: 'Luis Ramos',
    email: 'luis.ramos@muni.gob.pe',
    hashPassword: '$2b$12$PLACEHOLDER',
    rol: 'RESPONSABLE',
  },
  {
    nombre: 'Cuadrilla Sur',
    email: 'cuadrilla.sur@muni.gob.pe',
    hashPassword: '$2b$12$PLACEHOLDER',
    rol: 'RESPONSABLE',
  },
  {
    nombre: 'Rosa Meza',
    email: 'rosa.meza@muni.gob.pe',
    hashPassword: '$2b$12$PLACEHOLDER',
    rol: 'SUPERVISOR',
  },
  { nombre: 'Admin', email: 'admin@muni.gob.pe', hashPassword: '$2b$12$PLACEHOLDER', rol: 'ADMIN' },
];
