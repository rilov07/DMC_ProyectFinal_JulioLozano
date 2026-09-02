import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

// ADR-0004: citizen testimony, IMMUTABLE after submission.
// incidencia_id NULL = pending in the validation inbox.
@Entity('reporte')
export class ReporteEntity {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id!: string;

  @Column({ type: 'text', unique: true, insert: false, update: false })
  folio!: string;

  @Column({ name: 'tipo_incidencia_id', type: 'int' })
  tipoIncidenciaId!: number;

  @Column({ type: 'text', nullable: true })
  descripcion!: string | null;

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

  @Column({ name: 'fuera_de_ambito', type: 'boolean', default: false })
  fueraDeAmbito!: boolean;

  @Column({ name: 'contacto_opcional', type: 'text', nullable: true })
  contactoOpcional!: string | null;

  @Column({ name: 'ip_origen', type: 'inet', nullable: true })
  ipOrigen!: string | null;

  @Column({ name: 'creado_en', type: 'timestamptz' })
  creadoEn!: Date;

  @Column({ name: 'incidencia_id', type: 'bigint', nullable: true })
  incidenciaId!: string | null;

  @Column({ name: 'agrupado_automaticamente', type: 'boolean', default: false })
  agrupadoAutomaticamente!: boolean;

  @Column({ name: 'agrupacion_confirmada', type: 'boolean', default: false })
  agrupacionConfirmada!: boolean;

  @Column({ name: 'respuesta_duplicado_ciudadano', type: 'boolean', nullable: true })
  respuestaDuplicadoCiudadano!: boolean | null;

  @Column({ name: 'borrador_id', type: 'uuid', unique: true, nullable: true })
  borradorId!: string | null;
}
