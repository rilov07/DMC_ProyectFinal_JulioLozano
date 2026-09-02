# ADR 0003: Persistencia en PostgreSQL con la extensión PostGIS

## Estado

Aceptado

## Contexto

La georreferenciación es el eje del producto, no un atributo secundario. El PRD exige que el 100%
de los reportes queden almacenados con coordenadas geográficas válidas, que el validador pueda
identificar duplicados por "mismo tipo, radio configurable de cercanía y ventana de tiempo
configurable", y que el dashboard muestre distribución geográfica por zona y mapa de calor. El
Design.md añade el polígono de ámbito geográfico: un reporte cuyas coordenadas caen fuera de él
debe llegar marcado como `FUERA ÁMB.` a la bandeja de validación.

Al mismo tiempo, el dominio es fuertemente relacional y auditable: usuarios con rol, catálogo
cerrado de tipos de incidencia, asignaciones con responsable y plazo, y un historial de solo
lectura donde cada transición registra usuario, fecha-hora, estado anterior y estado nuevo. El PRD
lo exige explícitamente como criterio de éxito.

## Decisión

La persistencia es **PostgreSQL con la extensión PostGIS habilitada**. Las coordenadas de un
reporte se almacenan en una columna de tipo `geography(Point, 4326)` con índice GiST, y el ámbito
geográfico como `geography(Polygon, 4326)`. La búsqueda de duplicados se resuelve con `ST_DWithin`
sobre esa columna, filtrando además por tipo de incidencia y ventana de tiempo; la verificación de
ámbito, con `ST_Within` / `ST_Covers`.

## Alternativas consideradas

- **MongoDB con índices `2dsphere`** — Resuelve correctamente la búsqueda por radio y su esquema
  flexible habría facilitado evolucionar la forma del reporte. Se descartó porque el resto del
  modelo es marcadamente relacional (usuarios, roles, catálogo, asignaciones, historial) y porque
  la auditoría exigida por el PRD se apoya en integridad referencial y en transacciones que
  escriban el cambio de estado y su entrada de historial de forma atómica — garantías que en este
  motor habría que construir a mano.
- **MySQL / MariaDB con tipos espaciales** — Cumple lo mínimo: tiene tipos geométricos e índices
  espaciales suficientes para el radio de duplicados, y es un motor conocido. Se descartó porque su
  soporte geográfico es sensiblemente más pobre que el de PostGIS: el cálculo de distancias sobre
  el elipsoide, la agregación por zona y la construcción del mapa de calor exigirían más trabajo
  manual y darían resultados menos precisos.

## Consecuencias

- `ST_DWithin` sobre `geography` calcula distancias en metros reales sobre el elipsoide, así que el
  "radio configurable de cercanía" del PRD se expresa en la unidad que el equipo operativo entiende
  (metros) sin conversiones ni aproximaciones planas.
- El índice GiST mantiene la consulta de duplicados eficiente aunque la tabla de reportes crezca, lo
  que importa porque esa consulta se ejecuta en el momento de crear cada reporte (caso borde E3 del
  Design.md) y no solo en la bandeja del validador.
- Las transacciones de PostgreSQL permiten que un cambio de estado y su entrada de historial se
  escriban de forma atómica: no puede existir una incidencia cuyo estado avanzó sin dejar rastro.
- El polígono de ámbito vive en la base y no en el código, así que ajustar el ámbito geográfico es
  un cambio de dato, no un despliegue.
- **Costo:** PostGIS es una extensión con su propio vocabulario (SRID, `geography` vs `geometry`,
  familias de índices) que hay que aprender, y complica el entorno local — la base de datos deja de
  ser un Postgres cualquiera y exige una imagen o instalación con la extensión disponible.
- **Costo:** al escribir las consultas espaciales como SQL explícito (ver [ADR-0002](0002-stack-nestjs-typescript.md)),
  esa parte del acceso a datos queda fuera de las abstracciones del ORM y necesita pruebas de
  integración contra una base real para validarse.
