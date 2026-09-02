import { MigrationInterface, QueryRunner } from 'typeorm';

// Ports the STRUCTURE of db/01-schema.sql only: enum types, sequences,
// tables, columns, and CHECK/FK constraints.
//
// Deliberately EXCLUDED (deferred to the NestJS domain layer, backlog items
// #10-#14, per db/README.md "Diferencia deliberada" and
// Design: Andamiaje y esquema de base, Decision 3):
//   - fn_historial_inmutable / trg_historial_inmutable
//   - fn_registrar_historial / trg_historial_incidencia
//   - fn_resuelto_exige_evidencia / trg_resuelto_exige_evidencia
//   - fn_transicion_valida / trg_transicion_valida
//   - fn_ingresar_reporte
//   - fn_desagrupar_reporte
export class CreateSchema1700000000001 implements MigrationInterface {
  name = 'CreateSchema1700000000001';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // --- Enum types ------------------------------------------------------
    await queryRunner.query(`
      CREATE TYPE estado_incidencia AS ENUM (
          'reportado', 'validado', 'asignado', 'en_proceso', 'resuelto', 'descartado'
      )
    `);
    await queryRunner.query(
      `CREATE TYPE causal_descarte AS ENUM ('rechazado', 'duplicado', 'fuera_de_ambito')`,
    );
    await queryRunner.query(`CREATE TYPE prioridad AS ENUM ('ALTA', 'MEDIA', 'BAJA')`);
    await queryRunner.query(
      `CREATE TYPE rol_usuario AS ENUM ('VALIDADOR', 'RESPONSABLE', 'SUPERVISOR', 'ADMIN')`,
    );
    await queryRunner.query(`CREATE TYPE tipo_evidencia AS ENUM ('REPORTE', 'CIERRE')`);
    await queryRunner.query(`CREATE TYPE estado_carga AS ENUM ('COMPLETA', 'PENDIENTE')`);
    await queryRunner.query(`CREATE TYPE actor_tipo AS ENUM ('USUARIO', 'SISTEMA')`);
    await queryRunner.query(
      `CREATE TYPE tipo_notificacion AS ENUM ('ASIGNACION', 'CAMBIO_ESTADO', 'ESCALAMIENTO')`,
    );

    // --- zona --------------------------------------------------------------
    await queryRunner.query(`
      CREATE TABLE zona (
          id        SERIAL PRIMARY KEY,
          nombre    TEXT NOT NULL UNIQUE,
          poligono  geography(Polygon, 4326) NOT NULL,
          activa    BOOLEAN NOT NULL DEFAULT TRUE
      )
    `);

    // --- tipo_incidencia -----------------------------------------------------
    await queryRunner.query(`
      CREATE TABLE tipo_incidencia (
          id                       SERIAL PRIMARY KEY,
          nombre                   TEXT NOT NULL UNIQUE,
          activo                   BOOLEAN NOT NULL DEFAULT TRUE,
          plazo_por_defecto_horas  INTEGER NOT NULL CHECK (plazo_por_defecto_horas > 0)
      )
    `);

    // --- usuario -------------------------------------------------------------
    await queryRunner.query(`
      CREATE TABLE usuario (
          id             SERIAL PRIMARY KEY,
          nombre         TEXT NOT NULL,
          email          TEXT NOT NULL UNIQUE,
          hash_password  TEXT NOT NULL,
          rol            rol_usuario NOT NULL,
          activo         BOOLEAN NOT NULL DEFAULT TRUE
      )
    `);

    // --- configuracion_duplicados --------------------------------------------
    await queryRunner.query(`
      CREATE TABLE configuracion_duplicados (
          id                       INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),
          radio_estricto_m         INTEGER NOT NULL DEFAULT 20,
          ventana_estricta_min     INTEGER NOT NULL DEFAULT 120,
          radio_sugerencia_m       INTEGER NOT NULL DEFAULT 150,
          ventana_sugerencia_min   INTEGER NOT NULL DEFAULT 2880,
          CHECK (radio_estricto_m <= radio_sugerencia_m),
          CHECK (ventana_estricta_min <= ventana_sugerencia_min)
      )
    `);

    // --- incidencia ------------------------------------------------------------
    await queryRunner.query(`CREATE SEQUENCE seq_folio_incidencia START 1`);
    await queryRunner.query(`
      CREATE TABLE incidencia (
          id                  BIGSERIAL PRIMARY KEY,
          folio               TEXT NOT NULL UNIQUE
                                  DEFAULT 'INC-' || LPAD(nextval('seq_folio_incidencia')::TEXT, 6, '0'),
          tipo_incidencia_id  INTEGER NOT NULL REFERENCES tipo_incidencia(id),
          ubicacion           geography(Point, 4326) NOT NULL,
          zona_id             INTEGER REFERENCES zona(id),
          estado              estado_incidencia NOT NULL DEFAULT 'validado',
          causal              causal_descarte,
          responsable_id      INTEGER REFERENCES usuario(id),
          prioridad           prioridad,
          plazo_en            TIMESTAMPTZ,
          escalada_en         TIMESTAMPTZ,
          creada_en           TIMESTAMPTZ NOT NULL DEFAULT now(),
          resuelta_en         TIMESTAMPTZ,

          CONSTRAINT chk_descarte_exige_causal
              CHECK (estado <> 'descartado' OR causal IS NOT NULL),

          CONSTRAINT chk_asignacion_completa
              CHECK (
                  estado IN ('reportado', 'validado', 'descartado')
                  OR (responsable_id IS NOT NULL AND prioridad IS NOT NULL AND plazo_en IS NOT NULL)
              ),

          CONSTRAINT chk_resuelta_en_coherente
              CHECK ((estado = 'resuelto') = (resuelta_en IS NOT NULL))
      )
    `);

    // --- reporte -----------------------------------------------------------
    await queryRunner.query(`CREATE SEQUENCE seq_folio_reporte START 1`);
    await queryRunner.query(`
      CREATE TABLE reporte (
          id                            BIGSERIAL PRIMARY KEY,
          folio                         TEXT NOT NULL UNIQUE
                                            DEFAULT 'REP-' || LPAD(nextval('seq_folio_reporte')::TEXT, 6, '0'),
          tipo_incidencia_id            INTEGER NOT NULL REFERENCES tipo_incidencia(id),
          descripcion                   TEXT,
          ubicacion                     geography(Point, 4326) NOT NULL,
          zona_id                       INTEGER REFERENCES zona(id),
          fuera_de_ambito               BOOLEAN NOT NULL DEFAULT FALSE,
          contacto_opcional             TEXT,
          ip_origen                     INET,
          creado_en                     TIMESTAMPTZ NOT NULL DEFAULT now(),
          incidencia_id                 BIGINT REFERENCES incidencia(id) ON DELETE SET NULL,
          agrupado_automaticamente      BOOLEAN NOT NULL DEFAULT FALSE,
          agrupacion_confirmada         BOOLEAN NOT NULL DEFAULT FALSE,
          respuesta_duplicado_ciudadano BOOLEAN,
          borrador_id                   UUID UNIQUE,

          CONSTRAINT chk_agrupacion_coherente
              CHECK (NOT agrupado_automaticamente OR incidencia_id IS NOT NULL),
          CONSTRAINT chk_confirmacion_coherente
              CHECK (NOT agrupacion_confirmada OR agrupado_automaticamente)
      )
    `);

    // --- evidencia -----------------------------------------------------------
    await queryRunner.query(`
      CREATE TABLE evidencia (
          id             BIGSERIAL PRIMARY KEY,
          reporte_id     BIGINT REFERENCES reporte(id) ON DELETE CASCADE,
          incidencia_id  BIGINT REFERENCES incidencia(id) ON DELETE CASCADE,
          tipo           tipo_evidencia NOT NULL,
          ruta_relativa  TEXT NOT NULL,
          estado_carga   estado_carga NOT NULL DEFAULT 'PENDIENTE',
          tamano_bytes   BIGINT,
          mime           TEXT,
          creada_en      TIMESTAMPTZ NOT NULL DEFAULT now(),

          CONSTRAINT chk_evidencia_dueno_unico
              CHECK ((reporte_id IS NULL) <> (incidencia_id IS NULL)),
          CONSTRAINT chk_evidencia_tipo_coherente
              CHECK ((tipo = 'CIERRE') = (incidencia_id IS NOT NULL))
      )
    `);

    // --- historial_incidencia -------------------------------------------------
    await queryRunner.query(`
      CREATE TABLE historial_incidencia (
          id              BIGSERIAL PRIMARY KEY,
          incidencia_id   BIGINT NOT NULL REFERENCES incidencia(id) ON DELETE CASCADE,
          estado_anterior estado_incidencia,
          estado_nuevo    estado_incidencia NOT NULL,
          actor_id        INTEGER REFERENCES usuario(id),
          actor_tipo      actor_tipo NOT NULL,
          comentario      TEXT,
          creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),

          CONSTRAINT chk_actor_coherente
              CHECK ((actor_tipo = 'SISTEMA') = (actor_id IS NULL))
      )
    `);

    // --- notificacion ----------------------------------------------------------
    await queryRunner.query(`
      CREATE TABLE notificacion (
          id             BIGSERIAL PRIMARY KEY,
          usuario_id     INTEGER NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
          incidencia_id  BIGINT NOT NULL REFERENCES incidencia(id) ON DELETE CASCADE,
          tipo           tipo_notificacion NOT NULL,
          leida_en       TIMESTAMPTZ,
          creada_en      TIMESTAMPTZ NOT NULL DEFAULT now()
      )
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS notificacion`);
    await queryRunner.query(`DROP TABLE IF EXISTS historial_incidencia`);
    await queryRunner.query(`DROP TABLE IF EXISTS evidencia`);
    await queryRunner.query(`DROP TABLE IF EXISTS reporte`);
    await queryRunner.query(`DROP SEQUENCE IF EXISTS seq_folio_reporte`);
    await queryRunner.query(`DROP TABLE IF EXISTS incidencia`);
    await queryRunner.query(`DROP SEQUENCE IF EXISTS seq_folio_incidencia`);
    await queryRunner.query(`DROP TABLE IF EXISTS configuracion_duplicados`);
    await queryRunner.query(`DROP TABLE IF EXISTS usuario`);
    await queryRunner.query(`DROP TABLE IF EXISTS tipo_incidencia`);
    await queryRunner.query(`DROP TABLE IF EXISTS zona`);

    await queryRunner.query(`DROP TYPE IF EXISTS tipo_notificacion`);
    await queryRunner.query(`DROP TYPE IF EXISTS actor_tipo`);
    await queryRunner.query(`DROP TYPE IF EXISTS estado_carga`);
    await queryRunner.query(`DROP TYPE IF EXISTS tipo_evidencia`);
    await queryRunner.query(`DROP TYPE IF EXISTS rol_usuario`);
    await queryRunner.query(`DROP TYPE IF EXISTS prioridad`);
    await queryRunner.query(`DROP TYPE IF EXISTS causal_descarte`);
    await queryRunner.query(`DROP TYPE IF EXISTS estado_incidencia`);
  }
}
