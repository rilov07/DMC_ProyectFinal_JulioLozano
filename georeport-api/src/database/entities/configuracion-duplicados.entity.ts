import { Column, Entity, PrimaryColumn } from 'typeorm';

// ADR-0012: single-row configuration table. Radius/window thresholds are
// data, not code constants; defaults start deliberately conservative.
@Entity('configuracion_duplicados')
export class ConfiguracionDuplicadosEntity {
  @PrimaryColumn({ type: 'int' })
  id!: number;

  @Column({ name: 'radio_estricto_m', type: 'int', default: 20 })
  radioEstrictoM!: number;

  @Column({ name: 'ventana_estricta_min', type: 'int', default: 120 })
  ventanaEstrictaMin!: number;

  @Column({ name: 'radio_sugerencia_m', type: 'int', default: 150 })
  radioSugerenciaM!: number;

  @Column({ name: 'ventana_sugerencia_min', type: 'int', default: 2880 })
  ventanaSugerenciaMin!: number;
}
