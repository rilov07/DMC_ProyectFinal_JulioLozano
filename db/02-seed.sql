-- =============================================================================
-- GeoReport Vial — Datos de prueba
--
-- ATENCIÓN: los polígonos de zona son RECTÁNGULOS APROXIMADOS, no límites
-- distritales oficiales. Son un marcador de posición para probar el modelo.
-- Conseguir los polígonos reales del ámbito elegido es un riesgo abierto
-- declarado en TECH-DESIGN.md y el pendiente #1 del Design.md.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Zonas — el ámbito geográfico es la unión de estas (ADR-0006).
-- Rectángulos aproximados sobre Lima.
-- -----------------------------------------------------------------------------

INSERT INTO zona (nombre, poligono) VALUES
('Miraflores', ST_GeogFromText('POLYGON((-77.060 -12.140, -77.010 -12.140, -77.010 -12.100, -77.060 -12.100, -77.060 -12.140))')),
('San Isidro', ST_GeogFromText('POLYGON((-77.060 -12.100, -77.010 -12.100, -77.010 -12.070, -77.060 -12.070, -77.060 -12.100))')),
('Surco',      ST_GeogFromText('POLYGON((-77.010 -12.160, -76.960 -12.160, -76.960 -12.100, -77.010 -12.100, -77.010 -12.160))'));


-- -----------------------------------------------------------------------------
-- Catálogo de tipos de incidencia — el del PRD, completo.
-- Los plazos son VALORES DE PARTIDA sugeridos: el pendiente #4 del Design.md
-- pide fijarlos con el equipo operativo.
-- -----------------------------------------------------------------------------

INSERT INTO tipo_incidencia (nombre, plazo_por_defecto_horas) VALUES
('Pistas o carreteras en mal estado', 120),
('Bache',                              72),
('Accidente que interrumpe el tránsito', 4),
('Huaico',                              6),
('Derrumbe',                            8),
('Inundación',                          8),
('Problema de señalización',           96),
('Semáforo averiado',                  24),
('Daño en guardavías',                 72),
('Falla de drenaje',                   48),
('Túnel afectado',                     12),
('Puente dañado o bloqueado',           6);


-- -----------------------------------------------------------------------------
-- Usuarios internos. El ciudadano NO aparece aquí (ADR-0005).
-- Los hash son marcadores; en el sistema real, bcrypt/argon2 (ADR-0007).
-- -----------------------------------------------------------------------------

INSERT INTO usuario (nombre, email, hash_password, rol) VALUES
('Ana Quispe',    'ana.quispe@muni.gob.pe',    '$2b$12$PLACEHOLDER', 'VALIDADOR'),
('Luis Ramos',    'luis.ramos@muni.gob.pe',    '$2b$12$PLACEHOLDER', 'RESPONSABLE'),
('Cuadrilla Sur', 'cuadrilla.sur@muni.gob.pe', '$2b$12$PLACEHOLDER', 'RESPONSABLE'),
('Rosa Meza',     'rosa.meza@muni.gob.pe',     '$2b$12$PLACEHOLDER', 'SUPERVISOR'),
('Admin',         'admin@muni.gob.pe',         '$2b$12$PLACEHOLDER', 'ADMIN');


-- -----------------------------------------------------------------------------
-- Configuración de duplicados: arranca conservadora, como pide la ADR-0012.
-- -----------------------------------------------------------------------------

INSERT INTO configuracion_duplicados (id) VALUES (1);


-- =============================================================================
-- Escenario de prueba
-- =============================================================================

-- Actor de la sesión: la validadora Ana Quispe. La API fija esta variable por
-- petición; aquí la fijamos a mano para que el historial registre USUARIO.
SELECT set_config('georeport.actor_id', '1', FALSE);

-- --- 1. Primer reporte de un bache en Miraflores. ----------------------------
--     Sin incidencia abierta cercana: queda PENDIENTE en la bandeja.
SELECT fn_ingresar_reporte(
    p_tipo_incidencia_id := 2,                       -- Bache
    p_lon := -77.0300, p_lat := -12.1200,
    p_descripcion := 'Bache profundo en el carril derecho, av. principal',
    p_contacto := 'vecino@correo.com',
    p_ip := '190.12.44.10'
);

-- --- 2. La validadora lo valida: nace la Incidencia. -------------------------
WITH r AS (SELECT * FROM reporte WHERE folio = 'REP-000001')
INSERT INTO incidencia (tipo_incidencia_id, ubicacion, zona_id, estado)
SELECT r.tipo_incidencia_id, r.ubicacion, r.zona_id, 'validado' FROM r;

UPDATE reporte SET incidencia_id = (SELECT id FROM incidencia WHERE folio = 'INC-000001')
WHERE folio = 'REP-000001';

-- --- 3. Otro ciudadano reporta el MISMO bache, 12 metros más allá. -----------
--     Dentro del umbral estricto (20 m / 120 min) → AUTO-AGRUPADO (ADR-0012).
SELECT set_config('georeport.actor_id', '', FALSE);  -- el actor es el sistema
SELECT fn_ingresar_reporte(
    p_tipo_incidencia_id := 2,
    p_lon := -77.03011, p_lat := -12.12005,
    p_descripcion := 'Hueco grande, ya reventó una llanta',
    p_ip := '190.12.44.77'
);

-- --- 4. Un semáforo averiado en la MISMA esquina. ----------------------------
--     Mismo lugar pero distinto tipo → NO se agrupa. Queda pendiente.
SELECT fn_ingresar_reporte(
    p_tipo_incidencia_id := 8,                       -- Semáforo averiado
    p_lon := -77.03005, p_lat := -12.12002,
    p_descripcion := 'Semáforo apagado en la esquina'
);

-- --- 5. Un reporte FUERA del ámbito geográfico (caso borde E4). --------------
--     Se acepta, se guarda con zona nula y llega marcado FUERA ÁMB.
SELECT fn_ingresar_reporte(
    p_tipo_incidencia_id := 5,                       -- Derrumbe
    p_lon := -76.500, p_lat := -11.500,
    p_descripcion := 'Derrumbe en carretera, fuera de la ciudad'
);

-- --- 6. Reintento del mismo borrador (caso borde E5 / ADR-0013). -------------
--     Dos llamadas con el mismo borrador_id → UN SOLO reporte.
SELECT fn_ingresar_reporte(
    p_tipo_incidencia_id := 6,                       -- Inundación
    p_lon := -77.0000, p_lat := -12.1300,
    p_descripcion := 'Calle inundada por rotura de tubería',
    p_borrador_id := 'a0000000-0000-0000-0000-000000000001'
);
SELECT fn_ingresar_reporte(
    p_tipo_incidencia_id := 6,
    p_lon := -77.0000, p_lat := -12.1300,
    p_descripcion := 'Calle inundada por rotura de tubería',
    p_borrador_id := 'a0000000-0000-0000-0000-000000000001'
);

-- --- 7. Evidencia: una completa y una PENDIENTE (caso borde E2). -------------
INSERT INTO evidencia (reporte_id, tipo, ruta_relativa, estado_carga, tamano_bytes, mime)
SELECT id, 'REPORTE', '2026/09/REP-000001-a.jpg', 'COMPLETA', 842113, 'image/jpeg'
FROM reporte WHERE folio = 'REP-000001';

INSERT INTO evidencia (reporte_id, tipo, ruta_relativa, estado_carga)
SELECT id, 'REPORTE', '2026/09/REP-000002-a.jpg', 'PENDIENTE'
FROM reporte WHERE folio = 'REP-000002';

-- --- 8. Ciclo de vida completo de la incidencia INC-000001. ------------------
SELECT set_config('georeport.actor_id', '1', FALSE);   -- validadora

-- Asignación: responsable, prioridad y plazo JUNTOS (Design.md pantalla 06).
UPDATE incidencia
   SET estado = 'asignado',
       responsable_id = 2,
       prioridad = 'ALTA',
       plazo_en = now() + INTERVAL '72 hours'
 WHERE folio = 'INC-000001';

INSERT INTO notificacion (usuario_id, incidencia_id, tipo)
SELECT 2, id, 'ASIGNACION' FROM incidencia WHERE folio = 'INC-000001';

SELECT set_config('georeport.actor_id', '2', FALSE);   -- la cuadrilla

UPDATE incidencia SET estado = 'en_proceso' WHERE folio = 'INC-000001';

-- Evidencia de cierre: sin esto, pasar a 'resuelto' falla.
INSERT INTO evidencia (incidencia_id, tipo, ruta_relativa, estado_carga, tamano_bytes, mime)
SELECT id, 'CIERRE', '2026/09/INC-000001-cierre.jpg', 'COMPLETA', 1204880, 'image/jpeg'
FROM incidencia WHERE folio = 'INC-000001';

UPDATE incidencia SET estado = 'resuelto', resuelta_en = now() WHERE folio = 'INC-000001';

-- --- 9. La validadora valida el semáforo: INC-000002, en estado 'validado'. --
--     Queda sin asignar, para tener un caso de cada estado.
SELECT set_config('georeport.actor_id', '1', FALSE);

WITH r AS (SELECT * FROM reporte WHERE folio = 'REP-000003')
INSERT INTO incidencia (tipo_incidencia_id, ubicacion, zona_id, estado)
SELECT r.tipo_incidencia_id, r.ubicacion, r.zona_id, 'validado' FROM r;

UPDATE reporte SET incidencia_id = (SELECT id FROM incidencia WHERE folio = 'INC-000002')
WHERE folio = 'REP-000003';

-- --- 10. Una incidencia con el plazo YA VENCIDO, para probar escalamiento. ---
SELECT set_config('georeport.actor_id', '1', FALSE);

INSERT INTO incidencia (tipo_incidencia_id, ubicacion, zona_id, estado, creada_en)
VALUES (12, ST_GeogFromText('POINT(-76.9800 -12.1300)'), 3, 'validado', now() - INTERVAL '5 days');

UPDATE incidencia
   SET estado = 'asignado', responsable_id = 3, prioridad = 'ALTA',
       plazo_en = now() - INTERVAL '2 days'
 WHERE id = (SELECT max(id) FROM incidencia);
