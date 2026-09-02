import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

// ADR-0006: the deployment's geographic scope is the union of active zones,
// not a code constant.
@Entity('zona')
export class ZonaEntity {
  @PrimaryGeneratedColumn({ type: 'int' })
  id!: number;

  @Column({ type: 'text', unique: true })
  nombre!: string;

  // ADR-0003: geography reads/writes go through raw SQL, never the ORM.
  @Column({
    type: 'geography',
    spatialFeatureType: 'Polygon',
    srid: 4326,
    select: false,
    insert: false,
    update: false,
  })
  poligono!: string;

  @Column({ type: 'boolean', default: true })
  activa!: boolean;
}
