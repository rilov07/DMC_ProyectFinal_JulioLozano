import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';
import { EstadoCarga, TipoEvidencia } from './enums';

// ADR-0008: metadata only — the binary lives on disk.
@Entity('evidencia')
export class EvidenciaEntity {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id!: string;

  @Column({ name: 'reporte_id', type: 'bigint', nullable: true })
  reporteId!: string | null;

  @Column({ name: 'incidencia_id', type: 'bigint', nullable: true })
  incidenciaId!: string | null;

  @Column({ type: 'enum', enum: TipoEvidencia, enumName: 'tipo_evidencia' })
  tipo!: TipoEvidencia;

  @Column({ name: 'ruta_relativa', type: 'text' })
  rutaRelativa!: string;

  @Column({
    name: 'estado_carga',
    type: 'enum',
    enum: EstadoCarga,
    enumName: 'estado_carga',
    default: EstadoCarga.PENDIENTE,
  })
  estadoCarga!: EstadoCarga;

  @Column({ name: 'tamano_bytes', type: 'bigint', nullable: true })
  tamanoBytes!: string | null;

  @Column({ type: 'text', nullable: true })
  mime!: string | null;

  @Column({ name: 'creada_en', type: 'timestamptz' })
  creadaEn!: Date;
}
