-- =============================================================================
-- GeoReport Vial — Esquema de base de datos (modelo de prueba)
-- Deriva de TECH-DESIGN.md y de las ADR 0003, 0004, 0005, 0006, 0008 y 0012.
--
-- Motor: PostgreSQL 14+ con la extensión PostGIS (ADR-0003).
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS postgis;

-- -----------------------------------------------------------------------------
-- Tipos enumerados — vocabulario cerrado del Design.md (componente Indicators
-- & Badges) y del modelo de estados.
-- -----------------------------------------------------------------------------

CREATE TYPE estado_incidencia AS ENUM (
    'reportado', 'validado', 'asignado', 'en_proceso', 'resuelto', 'descartado'
);

CREATE TYPE causal_descarte AS ENUM ('rechazado', 'duplicado', 'fuera_de_ambito');

CREATE TYPE prioridad AS ENUM ('ALTA', 'MEDIA', 'BAJA');

CREATE TYPE rol_usuario AS ENUM ('VALIDADOR', 'RESPONSABLE', 'SUPERVISOR', 'ADMIN');

CREATE TYPE tipo_evidencia AS ENUM ('REPORTE', 'CIERRE');

CREATE TYPE estado_carga AS ENUM ('COMPLETA', 'PENDIENTE');

CREATE TYPE actor_tipo AS ENUM ('USUARIO', 'SISTEMA');

CREATE TYPE tipo_notificacion AS ENUM ('ASIGNACION', 'CAMBIO_ESTADO', 'ESCALAMIENTO');


-- -----------------------------------------------------------------------------
-- Zona — ADR-0006. El ámbito geográfico del despliegue es la unión de las zonas
-- activas; no es una constante del código.
-- -----------------------------------------------------------------------------

CREATE TABLE zona (
    id        SERIAL PRIMARY KEY,
    nombre    TEXT NOT NULL UNIQUE,
    poligono  geography(Polygon, 4326) NOT NULL,
    activa    BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_zona_poligono ON zona USING GIST (poligono);


-- -----------------------------------------------------------------------------
-- Catálogo de tipos de incidencia — cerrado, definido por el PRD.
-- plazo_por_defecto_horas alimenta el escalamiento (pendiente #4 del Design.md:
-- los valores reales los debe fijar el equipo operativo).
-- -----------------------------------------------------------------------------

CREATE TABLE tipo_incidencia (
    id                       SERIAL PRIMARY KEY,
    nombre                   TEXT NOT NULL UNIQUE,
    activo                   BOOLEAN NOT NULL DEFAULT TRUE,
    plazo_por_defecto_horas  INTEGER NOT NULL CHECK (plazo_por_defecto_horas > 0)
);


-- -----------------------------------------------------------------------------
-- Usuario — SOLO roles internos. El ciudadano no tiene registro (ADR-0005).
-- -----------------------------------------------------------------------------

CREATE TABLE usuario (
    id             SERIAL PRIMARY KEY,
    nombre         TEXT NOT NULL,
    email          TEXT NOT NULL UNIQUE,
    hash_password  TEXT NOT NULL,
    rol            rol_usuario NOT NULL,
    activo         BOOLEAN NOT NULL DEFAULT TRUE
);


-- -----------------------------------------------------------------------------
-- Configuración de duplicados — ADR-0012. El PRD exige radio y ventana
-- "configurables": son dato, no constantes en el código. Tabla de una sola fila.
-- Los valores por defecto arrancan deliberadamente conservadores.
-- -----------------------------------------------------------------------------

CREATE TABLE configuracion_duplicados (
    id                       INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    radio_estricto_m         INTEGER NOT NULL DEFAULT 20,
    ventana_estricta_min     INTEGER NOT NULL DEFAULT 120,
    radio_sugerencia_m       INTEGER NOT NULL DEFAULT 150,
    ventana_sugerencia_min   INTEGER NOT NULL DEFAULT 2880,
    CHECK (radio_estricto_m <= radio_sugerencia_m),
    CHECK (ventana_estricta_min <= ventana_sugerencia_min)
);


-- -----------------------------------------------------------------------------
-- Incidencia — ADR-0004. Unidad de trabajo del equipo operativo: lo ÚNICO que
-- tiene estado, responsable e historial.
-- -----------------------------------------------------------------------------

CREATE SEQUENCE seq_folio_incidencia START 1;

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

    -- Design.md: `descartado` exige causal.
    CONSTRAINT chk_descarte_exige_causal
        CHECK (estado <> 'descartado' OR causal IS NOT NULL),

    -- Design.md pantalla 06: la asignación exige responsable, prioridad y plazo
    -- JUNTOS — el plazo es lo que dispara el escalamiento.
    CONSTRAINT chk_asignacion_completa
        CHECK (
            estado IN ('reportado', 'validado', 'descartado')
            OR (responsable_id IS NOT NULL AND prioridad IS NOT NULL AND plazo_en IS NOT NULL)
        ),

    CONSTRAINT chk_resuelta_en_coherente
        CHECK ((estado = 'resuelto') = (resuelta_en IS NOT NULL))
);

CREATE INDEX idx_incidencia_ubicacion ON incidencia USING GIST (ubicacion);
CREATE INDEX idx_incidencia_estado    ON incidencia (estado);
CREATE INDEX idx_incidencia_zona      ON incidencia (zona_id);
-- Índice compuesto que sirve la búsqueda de duplicados: tipo + incidencias abiertas.
CREATE INDEX idx_incidencia_abiertas  ON incidencia (tipo_incidencia_id, creada_en)
    WHERE estado NOT IN ('resuelto', 'descartado');
-- Cola de vencidos de la pantalla 04.
CREATE INDEX idx_incidencia_plazo     ON incidencia (plazo_en)
    WHERE estado NOT IN ('resuelto', 'descartado');


-- -----------------------------------------------------------------------------
-- Reporte — ADR-0004. Testimonio ciudadano, INMUTABLE tras el envío.
-- incidencia_id NULL = pendiente en la bandeja de validación.
-- -----------------------------------------------------------------------------

CREATE SEQUENCE seq_folio_reporte START 1;

CREATE TABLE reporte (
    id                            BIGSERIAL PRIMARY KEY,
    folio                         TEXT NOT NULL UNIQUE
                                      DEFAULT 'REP-' || LPAD(nextval('seq_folio_reporte')::TEXT, 6, '0'),
    tipo_incidencia_id            INTEGER NOT NULL REFERENCES tipo_incidencia(id),
    descripcion                   TEXT,
    ubicacion                     geography(Point, 4326) NOT NULL,
    zona_id                       INTEGER REFERENCES zona(id),   -- derivada, ADR-0006
    fuera_de_ambito               BOOLEAN NOT NULL DEFAULT FALSE, -- señal FUERA ÁMB. (E4)
    contacto_opcional             TEXT,                           -- dato personal, ADR-0005
    ip_origen                     INET,                           -- señal de reincidencia, ADR-0005
    creado_en                     TIMESTAMPTZ NOT NULL DEFAULT now(),
    incidencia_id                 BIGINT REFERENCES incidencia(id) ON DELETE SET NULL,
    agrupado_automaticamente      BOOLEAN NOT NULL DEFAULT FALSE, -- señal AGRUPADO AUTO, ADR-0012
    agrupacion_confirmada         BOOLEAN NOT NULL DEFAULT FALSE,
    respuesta_duplicado_ciudadano BOOLEAN,                        -- señal de E3, nunca decisión
    borrador_id                   UUID UNIQUE,                    -- idempotencia, ADR-0013

    -- El PRD exige que tipo y ubicación sean los únicos obligatorios; la foto
    -- nunca bloquea el envío (Design.md pantalla 02).
    CONSTRAINT chk_agrupacion_coherente
        CHECK (NOT agrupado_automaticamente OR incidencia_id IS NOT NULL),
    CONSTRAINT chk_confirmacion_coherente
        CHECK (NOT agrupacion_confirmada OR agrupado_automaticamente)
);

CREATE INDEX idx_reporte_ubicacion ON reporte USING GIST (ubicacion);
-- Bandeja de validación: reportes sin incidencia asociada.
CREATE INDEX idx_reporte_pendiente ON reporte (creado_en) WHERE incidencia_id IS NULL;
CREATE INDEX idx_reporte_incidencia ON reporte (incidencia_id);
-- Búsqueda de duplicados en la creación: tipo + tiempo.
CREATE INDEX idx_reporte_tipo_tiempo ON reporte (tipo_incidencia_id, creado_en);


-- -----------------------------------------------------------------------------
-- Evidencia — ADR-0008. Solo metadatos; el binario vive en disco.
-- estado_carga PENDIENTE cubre el caso borde E2.
-- -----------------------------------------------------------------------------

CREATE TABLE evidencia (
    id             BIGSERIAL PRIMARY KEY,
    reporte_id     BIGINT REFERENCES reporte(id) ON DELETE CASCADE,
    incidencia_id  BIGINT REFERENCES incidencia(id) ON DELETE CASCADE,
    tipo           tipo_evidencia NOT NULL,
    ruta_relativa  TEXT NOT NULL,   -- relativa, para poder migrar a object storage
    estado_carga   estado_carga NOT NULL DEFAULT 'PENDIENTE',
    tamano_bytes   BIGINT,
    mime           TEXT,
    creada_en      TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Cuelga de un reporte (evidencia de reporte) o de una incidencia
    -- (evidencia de cierre), nunca de ambos ni de ninguno.
    CONSTRAINT chk_evidencia_dueno_unico
        CHECK ((reporte_id IS NULL) <> (incidencia_id IS NULL)),
    CONSTRAINT chk_evidencia_tipo_coherente
        CHECK ((tipo = 'CIERRE') = (incidencia_id IS NOT NULL))
);

CREATE INDEX idx_evidencia_reporte    ON evidencia (reporte_id);
CREATE INDEX idx_evidencia_incidencia ON evidencia (incidencia_id);
-- Deuda de evidencia pendiente (costo señalado en la ADR-0013).
CREATE INDEX idx_evidencia_pendiente  ON evidencia (creada_en) WHERE estado_carga = 'PENDIENTE';


-- -----------------------------------------------------------------------------
-- Historial — append-only. El PRD lo exige como criterio de éxito y el
-- Design.md lo declara de solo lectura.
-- -----------------------------------------------------------------------------

CREATE TABLE historial_incidencia (
    id              BIGSERIAL PRIMARY KEY,
    incidencia_id   BIGINT NOT NULL REFERENCES incidencia(id) ON DELETE CASCADE,
    estado_anterior estado_incidencia,
    estado_nuevo    estado_incidencia NOT NULL,
    actor_id        INTEGER REFERENCES usuario(id),  -- NULL cuando el actor es el sistema
    actor_tipo      actor_tipo NOT NULL,
    comentario      TEXT,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT chk_actor_coherente
        CHECK ((actor_tipo = 'SISTEMA') = (actor_id IS NULL))
);

CREATE INDEX idx_historial_incidencia ON historial_incidencia (incidencia_id, creado_en);


-- -----------------------------------------------------------------------------
-- Notificaciones internas. El PRD excluye avisos masivos a la ciudadanía.
-- -----------------------------------------------------------------------------

CREATE TABLE notificacion (
    id             BIGSERIAL PRIMARY KEY,
    usuario_id     INTEGER NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
    incidencia_id  BIGINT NOT NULL REFERENCES incidencia(id) ON DELETE CASCADE,
    tipo           tipo_notificacion NOT NULL,
    leida_en       TIMESTAMPTZ,
    creada_en      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_notificacion_no_leidas ON notificacion (usuario_id) WHERE leida_en IS NULL;


-- =============================================================================
-- Invariantes de dominio en la base
--
-- Nota: en el sistema real estas reglas viven en la capa de dominio de
-- georeport-api (ADR-0001). Aquí se implementan en la base para que el modelo
-- de prueba sea verificable por sí solo y para dejar la invariante escrita en
-- un solo lugar auditable.
-- =============================================================================

-- 1. El historial es de SOLO LECTURA. -----------------------------------------

CREATE OR REPLACE FUNCTION fn_historial_inmutable() RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'El historial de incidencias es de solo lectura (append-only)';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_historial_inmutable
    BEFORE UPDATE OR DELETE ON historial_incidencia
    FOR EACH ROW EXECUTE FUNCTION fn_historial_inmutable();


-- 2. Toda transición de estado escribe historial, en la MISMA transacción. ----
--    Criterio de aceptación del flujo 3: no existe incidencia cuyo número de
--    transiciones difiera de su número de entradas de historial.
--    El actor se pasa por variable de sesión; la API la fija por petición.

CREATE OR REPLACE FUNCTION fn_registrar_historial() RETURNS TRIGGER AS $$
DECLARE
    v_actor_id INTEGER;
BEGIN
    IF TG_OP = 'UPDATE' AND NEW.estado IS NOT DISTINCT FROM OLD.estado THEN
        RETURN NEW;
    END IF;

    v_actor_id := NULLIF(current_setting('georeport.actor_id', TRUE), '')::INTEGER;

    INSERT INTO historial_incidencia (
        incidencia_id, estado_anterior, estado_nuevo, actor_id, actor_tipo, comentario
    ) VALUES (
        NEW.id,
        CASE WHEN TG_OP = 'UPDATE' THEN OLD.estado ELSE NULL END,
        NEW.estado,
        v_actor_id,
        CASE WHEN v_actor_id IS NULL THEN 'SISTEMA' ELSE 'USUARIO' END,
        NULLIF(current_setting('georeport.comentario', TRUE), '')
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_historial_incidencia
    AFTER INSERT OR UPDATE OF estado ON incidencia
    FOR EACH ROW EXECUTE FUNCTION fn_registrar_historial();


-- 3. `resuelto` exige al menos una foto de evidencia de cierre COMPLETA. ------
--    Regla del Design.md, no expresable como CHECK por cruzar tablas.

CREATE OR REPLACE FUNCTION fn_resuelto_exige_evidencia() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado = 'resuelto' AND (TG_OP = 'INSERT' OR OLD.estado <> 'resuelto') THEN
        IF NOT EXISTS (
            SELECT 1 FROM evidencia
            WHERE incidencia_id = NEW.id
              AND tipo = 'CIERRE'
              AND estado_carga = 'COMPLETA'
        ) THEN
            RAISE EXCEPTION
                'La incidencia % no puede pasar a resuelto sin evidencia de cierre completa',
                NEW.folio;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_resuelto_exige_evidencia
    BEFORE INSERT OR UPDATE OF estado ON incidencia
    FOR EACH ROW EXECUTE FUNCTION fn_resuelto_exige_evidencia();


-- 4. Solo se aceptan las transiciones del modelo de estados del Design.md. ----
--    reportado → validado → asignado → en proceso → resuelto
--         ↘ descartado (desde cualquier estado no terminal)

CREATE OR REPLACE FUNCTION fn_transicion_valida() RETURNS TRIGGER AS $$
DECLARE
    v_permitida BOOLEAN;
BEGIN
    IF NEW.estado IS NOT DISTINCT FROM OLD.estado THEN
        RETURN NEW;
    END IF;

    v_permitida := CASE
        WHEN NEW.estado = 'descartado'
             AND OLD.estado NOT IN ('resuelto', 'descartado')          THEN TRUE
        WHEN OLD.estado = 'reportado'  AND NEW.estado = 'validado'     THEN TRUE
        WHEN OLD.estado = 'validado'   AND NEW.estado = 'asignado'     THEN TRUE
        WHEN OLD.estado = 'asignado'   AND NEW.estado = 'en_proceso'   THEN TRUE
        WHEN OLD.estado = 'en_proceso' AND NEW.estado = 'resuelto'     THEN TRUE
        ELSE FALSE
    END;

    IF NOT v_permitida THEN
        RAISE EXCEPTION 'Transición de estado no permitida: % → % (incidencia %)',
            OLD.estado, NEW.estado, NEW.folio;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_transicion_valida
    BEFORE UPDATE OF estado ON incidencia
    FOR EACH ROW EXECUTE FUNCTION fn_transicion_valida();


-- =============================================================================
-- Ingreso de un reporte: derivación de zona (ADR-0006) + auto-agrupación
-- reversible bajo umbral estricto (ADR-0012).
--
-- Ambas consultas espaciales van en la ruta crítica de creación, así que
-- ninguna puede bloquear el envío: si algo falla, el reporte se guarda igual y
-- queda pendiente en la bandeja.
-- =============================================================================

CREATE OR REPLACE FUNCTION fn_ingresar_reporte(
    p_tipo_incidencia_id  INTEGER,
    p_lon                 DOUBLE PRECISION,
    p_lat                 DOUBLE PRECISION,
    p_descripcion         TEXT DEFAULT NULL,
    p_contacto            TEXT DEFAULT NULL,
    p_ip                  INET DEFAULT NULL,
    p_borrador_id         UUID DEFAULT NULL
) RETURNS reporte AS $$
DECLARE
    v_punto       geography(Point, 4326);
    v_zona_id     INTEGER;
    v_cfg         configuracion_duplicados;
    v_incidencia  BIGINT;
    v_reporte     reporte;
BEGIN
    -- Idempotencia del reintento (ADR-0013): el mismo borrador nunca produce
    -- dos reportes.
    IF p_borrador_id IS NOT NULL THEN
        SELECT * INTO v_reporte FROM reporte WHERE borrador_id = p_borrador_id;
        IF FOUND THEN
            RETURN v_reporte;
        END IF;
    END IF;

    v_punto := ST_SetSRID(ST_MakePoint(p_lon, p_lat), 4326)::geography;

    -- Derivación de zona: nadie la elige, se calcula (ADR-0006).
    SELECT z.id INTO v_zona_id
    FROM zona z
    WHERE z.activa AND ST_Covers(z.poligono, v_punto)
    LIMIT 1;

    SELECT * INTO v_cfg FROM configuracion_duplicados WHERE id = 1;

    -- Auto-agrupación bajo umbral ESTRICTO: mismo tipo, incidencia abierta,
    -- dentro del radio y la ventana estrictos. La más cercana gana.
    SELECT i.id INTO v_incidencia
    FROM incidencia i
    WHERE i.tipo_incidencia_id = p_tipo_incidencia_id
      AND i.estado NOT IN ('resuelto', 'descartado')
      AND i.creada_en >= now() - make_interval(mins => v_cfg.ventana_estricta_min)
      AND ST_DWithin(i.ubicacion, v_punto, v_cfg.radio_estricto_m)
    ORDER BY ST_Distance(i.ubicacion, v_punto)
    LIMIT 1;

    INSERT INTO reporte (
        tipo_incidencia_id, descripcion, ubicacion, zona_id, fuera_de_ambito,
        contacto_opcional, ip_origen, incidencia_id, agrupado_automaticamente,
        borrador_id
    ) VALUES (
        p_tipo_incidencia_id, p_descripcion, v_punto, v_zona_id, v_zona_id IS NULL,
        p_contacto, p_ip, v_incidencia, v_incidencia IS NOT NULL,
        p_borrador_id
    )
    RETURNING * INTO v_reporte;

    -- La auto-agrupación deja rastro en el historial con actor SISTEMA.
    IF v_incidencia IS NOT NULL THEN
        INSERT INTO historial_incidencia (
            incidencia_id, estado_anterior, estado_nuevo, actor_id, actor_tipo, comentario
        )
        SELECT v_incidencia, i.estado, i.estado, NULL, 'SISTEMA',
               'Auto-agrupación del reporte ' || v_reporte.folio || ' bajo umbral estricto'
        FROM incidencia i WHERE i.id = v_incidencia;
    END IF;

    RETURN v_reporte;
END;
$$ LANGUAGE plpgsql;


-- Desagrupar: una sola acción, reversible, sin tocar estado ni borrar historial
-- de la incidencia de origen (condición bajo la que se adoptó la ADR-0012).

CREATE OR REPLACE FUNCTION fn_desagrupar_reporte(
    p_reporte_id INTEGER,
    p_actor_id   INTEGER
) RETURNS VOID AS $$
DECLARE
    v_incidencia BIGINT;
    v_folio      TEXT;
BEGIN
    SELECT incidencia_id, folio INTO v_incidencia, v_folio
    FROM reporte WHERE id = p_reporte_id;

    IF v_incidencia IS NULL THEN
        RAISE EXCEPTION 'El reporte % no está agrupado', p_reporte_id;
    END IF;

    UPDATE reporte
       SET incidencia_id = NULL,
           agrupado_automaticamente = FALSE,
           agrupacion_confirmada = FALSE
     WHERE id = p_reporte_id;

    INSERT INTO historial_incidencia (
        incidencia_id, estado_anterior, estado_nuevo, actor_id, actor_tipo, comentario
    )
    SELECT v_incidencia, i.estado, i.estado, p_actor_id, 'USUARIO',
           'Desagrupación del reporte ' || v_folio || ' — devuelto a la bandeja'
    FROM incidencia i WHERE i.id = v_incidencia;
END;
$$ LANGUAGE plpgsql;
