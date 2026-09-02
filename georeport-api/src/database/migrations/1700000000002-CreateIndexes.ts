import { MigrationInterface, QueryRunner } from 'typeorm';

// Isolated from CreateSchema so the spatial/GiST + partial-index diff
// against db/01-schema.sql stays independently reviewable.
export class CreateIndexes1700000000002 implements MigrationInterface {
  name = 'CreateIndexes1700000000002';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // zona
    await queryRunner.query(`CREATE INDEX idx_zona_poligono ON zona USING GIST (poligono)`);

    // incidencia
    await queryRunner.query(
      `CREATE INDEX idx_incidencia_ubicacion ON incidencia USING GIST (ubicacion)`,
    );
    await queryRunner.query(`CREATE INDEX idx_incidencia_estado ON incidencia (estado)`);
    await queryRunner.query(`CREATE INDEX idx_incidencia_zona ON incidencia (zona_id)`);
    await queryRunner.query(`
      CREATE INDEX idx_incidencia_abiertas ON incidencia (tipo_incidencia_id, creada_en)
          WHERE estado NOT IN ('resuelto', 'descartado')
    `);
    await queryRunner.query(`
      CREATE INDEX idx_incidencia_plazo ON incidencia (plazo_en)
          WHERE estado NOT IN ('resuelto', 'descartado')
    `);

    // reporte
    await queryRunner.query(`CREATE INDEX idx_reporte_ubicacion ON reporte USING GIST (ubicacion)`);
    await queryRunner.query(
      `CREATE INDEX idx_reporte_pendiente ON reporte (creado_en) WHERE incidencia_id IS NULL`,
    );
    await queryRunner.query(`CREATE INDEX idx_reporte_incidencia ON reporte (incidencia_id)`);
    await queryRunner.query(
      `CREATE INDEX idx_reporte_tipo_tiempo ON reporte (tipo_incidencia_id, creado_en)`,
    );

    // evidencia
    await queryRunner.query(`CREATE INDEX idx_evidencia_reporte ON evidencia (reporte_id)`);
    await queryRunner.query(`CREATE INDEX idx_evidencia_incidencia ON evidencia (incidencia_id)`);
    await queryRunner.query(`
      CREATE INDEX idx_evidencia_pendiente ON evidencia (creada_en) WHERE estado_carga = 'PENDIENTE'
    `);

    // historial_incidencia
    await queryRunner.query(
      `CREATE INDEX idx_historial_incidencia ON historial_incidencia (incidencia_id, creado_en)`,
    );

    // notificacion
    await queryRunner.query(`
      CREATE INDEX idx_notificacion_no_leidas ON notificacion (usuario_id) WHERE leida_en IS NULL
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS idx_notificacion_no_leidas`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_historial_incidencia`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_evidencia_pendiente`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_evidencia_incidencia`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_evidencia_reporte`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_reporte_tipo_tiempo`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_reporte_incidencia`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_reporte_pendiente`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_reporte_ubicacion`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_incidencia_plazo`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_incidencia_abiertas`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_incidencia_zona`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_incidencia_estado`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_incidencia_ubicacion`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_zona_poligono`);
  }
}
