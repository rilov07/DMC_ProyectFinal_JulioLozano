import { DataSource } from 'typeorm';
import { buildDataSourceOptions } from '../config/database.config';

// Consumed by the TypeORM CLI (`npm run -w georeport-api migration:run`,
// `migration:revert`) and by the seed scripts.
export default new DataSource(buildDataSourceOptions());
