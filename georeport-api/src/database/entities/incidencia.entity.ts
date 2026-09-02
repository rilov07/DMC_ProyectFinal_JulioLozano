import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';
import { CausalDescarte, EstadoIncidencia, Prioridad } from './enums';

// ADR-0004: the incidencia is the operational team's unit of work — the
// ONLY thing that has state, an owner, and history.
@Entity('incidencia')
export class IncidenciaEntity {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id!: string;

  // Sequence DEFAULT ('INC-000001'...); read back via RETURNING, never set
  // by the application.
  @Column({ type: 'text', unique: true, insert: false, update: false })
  folio!: string;

  @Column({ name: 'tipo_incidencia_id', type: 'int' })
  tipoIncidenciaId!: number;

  // ADR-0003: geography reads/writes go through raw SQL, never the ORM.
  @Column({
    type: 'geography',
    spatialFeatureType: 'Point',
    srid: 4326,
    select: false,
    insert: false,
    update: false,
  })
  ubicacion!: string;

  @Column({ name: 'zona_id', type: 'int', nullable: true })
  zonaId!: number | null;

  @Column({
    type: 'enum',
    enum: EstadoIncidencia,
    enumName: 'estado_incidencia',
    default: EstadoIncidencia.VALIDADO,
  })
  estado!: EstadoIncidencia;

  @Column({ type: 'enum', enum: CausalDescarte, enumName: 'causal_descarte', nullable: true })
  causal!: CausalDescarte | null;

  @Column({ name: 'responsable_id', type: 'int', nullable: true })
  responsableId!: number | null;

  @Column({ type: 'enum', enum: Prioridad, enumName: 'prioridad', nullable: true })
  prioridad!: Prioridad | null;

  @Column({ name: 'plazo_en', type: 'timestamptz', nullable: true })
  plazoEn!: Date | null;

  @Column({ name: 'escalada_en', type: 'timestamptz', nullable: true })
  escaladaEn!: Date | null;

  @Column({ name: 'creada_en', type: 'timestamptz' })
  creadaEn!: Date;

  @Column({ name: 'resuelta_en', type: 'timestamptz', nullable: true })
  resueltaEn!: Date | null;
}
