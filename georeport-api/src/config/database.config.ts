import type { DataSourceOptions } from 'typeorm';
import { config as loadEnv } from 'dotenv';

loadEnv();

// Env-driven DataSourceOptions shared by the NestJS runtime (via
// TypeOrmModule.forRoot) and the TypeORM CLI (via data-source.ts).
// synchronize is always false: schema changes only ever go through
// hand-written migrations (Design: Andamiaje y esquema de base, Decision 2).
export function buildDataSourceOptions(): DataSourceOptions {
  return {
    type: 'postgres',
    host: process.env.DB_HOST ?? 'localhost',
    port: Number(process.env.DB_PORT ?? 5433),
    username: process.env.DB_USER ?? 'georeport',
    password: process.env.DB_PASSWORD ?? 'georeport',
    database: process.env.DB_NAME ?? 'georeport',
    synchronize: false,
    entities: [__dirname + '/../database/entities/*.entity{.ts,.js}'],
    migrations: [__dirname + '/../database/migrations/*{.ts,.js}'],
    migrationsRun: false,
  };
}
