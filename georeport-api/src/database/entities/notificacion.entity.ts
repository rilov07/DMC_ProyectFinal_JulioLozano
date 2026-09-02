import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';
import { TipoNotificacion } from './enums';

// Internal notifications only. The PRD excludes mass alerts to citizens.
@Entity('notificacion')
export class NotificacionEntity {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id!: string;

  @Column({ name: 'usuario_id', type: 'int' })
  usuarioId!: number;

  @Column({ name: 'incidencia_id', type: 'bigint' })
  incidenciaId!: string;

  @Column({
    type: 'enum',
    enum: TipoNotificacion,
    enumName: 'tipo_notificacion',
  })
  tipo!: TipoNotificacion;

  @Column({ name: 'leida_en', type: 'timestamptz', nullable: true })
  leidaEn!: Date | null;

  @Column({ name: 'creada_en', type: 'timestamptz' })
  creadaEn!: Date;
}
