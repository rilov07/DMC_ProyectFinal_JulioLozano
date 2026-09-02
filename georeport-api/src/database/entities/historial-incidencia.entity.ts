import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';
import { ActorTipo, EstadoIncidencia } from './enums';

// Append-only. The PRD requires it as a success criterion and Design.md
// declares it read-only. Row insertion in this scaffold is deferred to the
// NestJS domain layer (items #10-#14) — no trigger exists yet.
@Entity('historial_incidencia')
export class HistorialIncidenciaEntity {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id!: string;

  @Column({ name: 'incidencia_id', type: 'bigint' })
  incidenciaId!: string;

  @Column({
    name: 'estado_anterior',
    type: 'enum',
    enum: EstadoIncidencia,
    enumName: 'estado_incidencia',
    nullable: true,
  })
  estadoAnterior!: EstadoIncidencia | null;

  @Column({
    name: 'estado_nuevo',
    type: 'enum',
    enum: EstadoIncidencia,
    enumName: 'estado_incidencia',
  })
  estadoNuevo!: EstadoIncidencia;

  @Column({ name: 'actor_id', type: 'int', nullable: true })
  actorId!: number | null;

  @Column({ name: 'actor_tipo', type: 'enum', enum: ActorTipo, enumName: 'actor_tipo' })
  actorTipo!: ActorTipo;

  @Column({ type: 'text', nullable: true })
  comentario!: string | null;

  @Column({ name: 'creado_en', type: 'timestamptz' })
  creadoEn!: Date;
}
