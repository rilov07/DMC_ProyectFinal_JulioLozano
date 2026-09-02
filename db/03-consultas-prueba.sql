-- =============================================================================
-- GeoReport Vial — Consultas de verificación del modelo
--
-- Cada bloque corresponde a un criterio de aceptación de TECH-DESIGN.md.
-- Ejecutar después de 01-schema.sql y 02-seed.sql.
-- =============================================================================

\echo '=== 1. Zona derivada y señal FUERA ÁMB. (ADR-0006, caso borde E4) ==='
-- Criterio: si las coordenadas caen en una zona activa, zona_id se resuelve
-- solo; si no, el reporte se persiste igual con zona nula y fuera_de_ambito.
SELECT r.folio,
       t.nombre                      AS tipo,
       COALESCE(z.nombre, '—')       AS zona,
       r.fuera_de_ambito,
       ST_Y(r.ubicacion::geometry)   AS lat,
       ST_X(r.ubicacion::geometry)   AS lon
FROM reporte r
JOIN tipo_incidencia t ON t.id = r.tipo_incidencia_id
LEFT JOIN zona z ON z.id = r.zona_id
ORDER BY r.folio;


\echo ''
\echo '=== 2. Auto-agrupación bajo umbral estricto (ADR-0012) ==='
-- Criterio: un reporte del mismo tipo dentro del radio y ventana estrictos se
-- adjunta a la incidencia abierta SIN crear una nueva, y queda AGRUPADO AUTO.
-- El semáforo, en la misma esquina pero de otro tipo, NO se agrupa.
SELECT r.folio,
       t.nombre                                     AS tipo,
       COALESCE(i.folio, 'PENDIENTE EN BANDEJA')    AS incidencia,
       CASE WHEN r.agrupado_automaticamente THEN 'AGRUPADO AUTO' ELSE '—' END AS senal,
       round(ST_Distance(r.ubicacion,
             (SELECT ubicacion FROM reporte WHERE folio = 'REP-000001'))::numeric, 1)
                                                    AS dist_a_rep1_m
FROM reporte r
JOIN tipo_incidencia t ON t.id = r.tipo_incidencia_id
LEFT JOIN incidencia i ON i.id = r.incidencia_id
ORDER BY r.folio;


\echo ''
\echo '=== 3. Bandeja de validación (pantalla 04) ==='
-- Criterio: la bandeja lista los reportes con incidencia_id nulo, MÁS las
-- incidencias con señal AGRUPADO AUTO sin confirmar.
SELECT 'REPORTE PENDIENTE' AS origen, r.folio, t.nombre AS tipo,
       COALESCE(z.nombre, 'FUERA ÁMB.') AS zona,
       age(now(), r.creado_en)          AS antiguedad
FROM reporte r
JOIN tipo_incidencia t ON t.id = r.tipo_incidencia_id
LEFT JOIN zona z ON z.id = r.zona_id
WHERE r.incidencia_id IS NULL
UNION ALL
SELECT 'AGRUPADO AUTO', i.folio, t.nombre,
       COALESCE(z.nombre, '—'), age(now(), i.creada_en)
FROM incidencia i
JOIN tipo_incidencia t ON t.id = i.tipo_incidencia_id
LEFT JOIN zona z ON z.id = i.zona_id
WHERE EXISTS (SELECT 1 FROM reporte r
              WHERE r.incidencia_id = i.id
                AND r.agrupado_automaticamente
                AND NOT r.agrupacion_confirmada);


\echo ''
\echo '=== 4. Candidatos a duplicado con radio y ventana AJUSTABLES (pantalla 05) ==='
-- Criterio: cambiar radio o ventana recalcula candidatos sin modificar dato
-- alguno. Aquí se pasan como parámetros, tal como hace el comparador.
SELECT r.folio,
       round(ST_Distance(r.ubicacion, ST_GeogFromText('POINT(-77.0300 -12.1200)'))::numeric, 1) AS dist_m,
       r.creado_en
FROM reporte r
WHERE r.tipo_incidencia_id = 2                                   -- mismo tipo
  AND ST_DWithin(r.ubicacion,
                 ST_GeogFromText('POINT(-77.0300 -12.1200)'),
                 150)                                            -- radio ajustable (m)
  AND r.creado_en >= now() - INTERVAL '48 hours'                 -- ventana ajustable
ORDER BY dist_m;


\echo ''
\echo '=== 5. Un solo responsable por incidencia agrupada (PRD, caso borde) ==='
-- Criterio: una incidencia con N reportes admite exactamente un responsable.
-- Es imposible violarlo: la asignación cuelga de Incidencia (ADR-0004).
SELECT i.folio,
       count(r.id)                        AS reportes_agrupados,
       COALESCE(u.nombre, 'sin asignar')  AS responsable_unico
FROM incidencia i
LEFT JOIN reporte r ON r.incidencia_id = i.id
LEFT JOIN usuario u ON u.id = i.responsable_id
GROUP BY i.folio, u.nombre
ORDER BY i.folio;


\echo ''
\echo '=== 6. Historial completo e íntegro (criterio de éxito del PRD) ==='
-- Criterio: toda transición escribe una entrada con estado anterior, nuevo,
-- actor y fecha-hora. El actor puede ser el SISTEMA (auto-agrupación).
SELECT i.folio,
       COALESCE(h.estado_anterior::TEXT, '(nuevo)') AS de,
       h.estado_nuevo                               AS a,
       h.actor_tipo,
       COALESCE(u.nombre, 'sistema')                AS actor,
       COALESCE(h.comentario, '')                   AS comentario,
       h.creado_en
FROM historial_incidencia h
JOIN incidencia i ON i.id = h.incidencia_id
LEFT JOIN usuario u ON u.id = h.actor_id
ORDER BY i.folio, h.creado_en;


\echo ''
\echo '=== 7. Seguimiento del ciudadano por folio (pantalla 03) ==='
-- Criterio: el folio permite consultar el estado sin credenciales. El estado
-- que se muestra es el de la INCIDENCIA asociada (ADR-0004).
SELECT r.folio                                   AS folio_reporte,
       t.nombre                                  AS tipo,
       COALESCE(i.estado::TEXT, 'en revisión')   AS estado_mostrado,
       COALESCE(i.folio, '—')                    AS incidencia
FROM reporte r
JOIN tipo_incidencia t ON t.id = r.tipo_incidencia_id
LEFT JOIN incidencia i ON i.id = r.incidencia_id
WHERE r.folio = 'REP-000002';


\echo ''
\echo '=== 8. Cola de vencidos y escalamiento (pantallas 04 y 09) ==='
-- Criterio: el job detecta incidencias con plazo vencido, no terminales y no
-- escaladas aún. escalada_en evita la notificación repetida.
SELECT i.folio, t.nombre AS tipo, i.estado, i.prioridad,
       u.nombre                    AS responsable,
       age(now(), i.plazo_en)      AS vencido_hace
FROM incidencia i
JOIN tipo_incidencia t ON t.id = i.tipo_incidencia_id
LEFT JOIN usuario u ON u.id = i.responsable_id
WHERE i.plazo_en < now()
  AND i.estado NOT IN ('resuelto', 'descartado')
  AND i.escalada_en IS NULL;


\echo ''
\echo '=== 9. Dashboard: conteo por estado, tipo y zona (pantalla 10) ==='
-- Criterio: el dashboard devuelve conteo por estado, por tipo y por zona, con
-- marca temporal de generación. Consultas baratas: se ejecutan cada minuto por
-- cada supervisor conectado (ADR-0011).
SELECT now() AS generado_en;

SELECT estado, count(*) AS total FROM incidencia GROUP BY estado ORDER BY total DESC;

SELECT t.nombre AS tipo, count(i.id) AS total
FROM tipo_incidencia t
LEFT JOIN incidencia i ON i.tipo_incidencia_id = t.id
GROUP BY t.nombre HAVING count(i.id) > 0 ORDER BY total DESC;

SELECT COALESCE(z.nombre, 'FUERA ÁMB.') AS zona, count(i.id) AS total
FROM incidencia i
LEFT JOIN zona z ON z.id = i.zona_id
GROUP BY z.nombre ORDER BY total DESC;


\echo ''
\echo '=== 10. Evidencia pendiente — la deuda del caso borde E2 (ADR-0013) ==='
SELECT e.id, r.folio AS reporte, e.tipo, e.estado_carga, e.ruta_relativa
FROM evidencia e
LEFT JOIN reporte r ON r.id = e.reporte_id
WHERE e.estado_carga = 'PENDIENTE';


-- =============================================================================
-- Pruebas NEGATIVAS: las reglas de dominio deben RECHAZAR estas operaciones.
-- Cada bloque debe imprimir el mensaje de error esperado y continuar.
-- =============================================================================

\echo ''
\echo '=== NEG-1: pasar a resuelto sin evidencia de cierre debe FALLAR ==='
DO $$
DECLARE v_id BIGINT;
BEGIN
    SELECT id INTO v_id FROM incidencia WHERE estado = 'asignado' LIMIT 1;
    UPDATE incidencia SET estado = 'en_proceso' WHERE id = v_id;
    UPDATE incidencia SET estado = 'resuelto', resuelta_en = now() WHERE id = v_id;
    RAISE WARNING 'FALLO: se permitió resolver sin evidencia de cierre';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'OK — rechazado: %', SQLERRM;
END $$;

\echo ''
\echo '=== NEG-2: transición inválida (validado → resuelto) debe FALLAR ==='
DO $$
BEGIN
    UPDATE incidencia SET estado = 'resuelto', resuelta_en = now()
    WHERE estado = 'validado';
    RAISE WARNING 'FALLO: se permitió una transición inválida';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'OK — rechazado: %', SQLERRM;
END $$;

\echo ''
\echo '=== NEG-3: descartar sin causal debe FALLAR ==='
DO $$
BEGIN
    UPDATE incidencia SET estado = 'descartado'
    WHERE folio = 'INC-000002';
    RAISE WARNING 'FALLO: se permitió descartar sin causal';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'OK — rechazado: %', SQLERRM;
END $$;

\echo ''
\echo '=== NEG-4: asignar sin plazo debe FALLAR ==='
DO $$
BEGIN
    UPDATE incidencia SET estado = 'asignado', responsable_id = 2, prioridad = 'MEDIA'
    WHERE estado = 'validado';
    RAISE WARNING 'FALLO: se permitió asignar sin plazo';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'OK — rechazado: %', SQLERRM;
END $$;

\echo ''
\echo '=== NEG-5: modificar o borrar el historial debe FALLAR ==='
DO $$
BEGIN
    UPDATE historial_incidencia SET comentario = 'alterado' WHERE id = 1;
    RAISE WARNING 'FALLO: el historial resultó modificable';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'OK — rechazado: %', SQLERRM;
END $$;

DO $$
BEGIN
    DELETE FROM historial_incidencia WHERE id = 1;
    RAISE WARNING 'FALLO: el historial resultó borrable';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'OK — rechazado: %', SQLERRM;
END $$;


-- =============================================================================
-- Reversibilidad de la auto-agrupación — la condición bajo la que se adoptó
-- la ADR-0012. Desagrupar devuelve el reporte a la bandeja sin tocar el estado
-- ni borrar el historial de la incidencia de origen.
-- =============================================================================

\echo ''
\echo '=== 11. Desagrupar es reversible y deja rastro ==='
SELECT fn_desagrupar_reporte(
    (SELECT id FROM reporte WHERE agrupado_automaticamente LIMIT 1),
    1
);

SELECT r.folio,
       COALESCE(i.folio, 'PENDIENTE EN BANDEJA') AS incidencia,
       r.agrupado_automaticamente
FROM reporte r
LEFT JOIN incidencia i ON i.id = r.incidencia_id
WHERE r.folio = 'REP-000002';

SELECT i.folio, i.estado AS estado_intacto, count(h.id) AS entradas_historial
FROM incidencia i
JOIN historial_incidencia h ON h.incidencia_id = i.id
WHERE i.folio = 'INC-000001'
GROUP BY i.folio, i.estado;
