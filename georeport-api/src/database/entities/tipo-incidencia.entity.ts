import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

// Closed catalog defined by the PRD.
@Entity('tipo_incidencia')
export class TipoIncidenciaEntity {
  @PrimaryGeneratedColumn({ type: 'int' })
  id!: number;

  @Column({ type: 'text', unique: true })
  nombre!: string;

  @Column({ type: 'boolean', default: true })
  activo!: boolean;

  @Column({ name: 'plazo_por_defecto_horas', type: 'int' })
  plazoPorDefectoHoras!: number;
}
