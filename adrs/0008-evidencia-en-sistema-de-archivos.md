# ADR 0008: Evidencia fotográfica en el sistema de archivos del servidor

## Estado

Aceptado

## Contexto

El PRD exige que el reporte incluya fotografías y el Design.md endurece el requisito en dos puntos:
el estado `resuelto` "exige al menos una foto de evidencia de cierre", y el componente *Evidence
Upload* debe mostrar el porcentaje sobre la miniatura y la etiqueta `PENDIENTE` cuando una carga
queda incompleta (caso borde E2: "el reporte debe poder guardarse igual, marcando la evidencia como
pendiente").

Es contenido binario y pesado, y el propio PRD lo señala como riesgo abierto: "el volumen esperado
de reportes y fotografías no está definido, lo cual afecta el dimensionamiento de almacenamiento e
infraestructura".

## Decisión

Las fotografías se guardan en el **sistema de archivos del servidor de `georeport-api`**, en un
directorio configurable respaldado por un volumen persistente. La base de datos guarda únicamente
los metadatos de cada evidencia: identificador, ruta relativa, tipo (evidencia de reporte o de
cierre), estado de carga (`COMPLETA` / `PENDIENTE`), tamaño y fecha. La API sirve las imágenes a
través de un endpoint propio, que aplica las mismas reglas de autorización que el resto del
dominio.

La ruta se almacena como **ruta relativa**, no absoluta, para que migrar a object storage más
adelante sea reemplazar el adaptador de almacenamiento sin tocar el modelo de datos.

## Alternativas consideradas

- **Object storage compatible con S3 (MinIO en desarrollo, S3/R2 en producción) con URLs
  prefirmadas** — Era la opción recomendada y la respuesta estándar al problema: el binario nunca
  atraviesa la API, el almacenamiento escala sin tocar el backend y el despliegue queda sin estado.
  Se descartó por decisión del usuario, priorizando no añadir un servicio más a la infraestructura
  de un proyecto sostenido por una persona.
- **BLOB en PostgreSQL (`bytea`)** — Habría dejado todo en un solo lugar, con respaldos triviales y
  la carga de la imagen dentro de la misma transacción que el reporte. Se descartó porque infla la
  base de datos, degrada el tiempo de respaldo y restauración, y hace que servir cada imagen pase
  por el motor de datos — un costo especialmente malo cuando el volumen es desconocido, que es
  justo lo que el PRD advierte.

## Consecuencias

- Cero infraestructura adicional: no hay un servicio de almacenamiento que desplegar, configurar ni
  mantener, y el entorno local se levanta solo con la API y PostgreSQL.
- El acceso a las imágenes pasa por la API, así que la autorización por rol se aplica de forma
  uniforme y no hay que razonar sobre permisos de bucket ni caducidad de URLs prefirmadas.
- Guardar solo metadatos en la base mantiene liviana la tabla y compatible con el estado
  `PENDIENTE` que el caso borde E2 exige representar.
- **Costo:** `georeport-api` deja de ser un servicio sin estado. Queda atada al disco donde viven
  las imágenes: no se puede correr más de una instancia sin un volumen compartido, y cualquier
  redespliegue que no preserve ese volumen destruye toda la evidencia. Sumado al scheduler embebido
  de la [ADR-0002](0002-stack-nestjs-typescript.md), el despliegue queda comprometido con una única
  instancia.
- **Costo:** cada descarga de imagen consume un worker del proceso de la API, así que una bandeja de
  validación con muchas miniaturas compite por los mismos recursos que las consultas del dashboard.
- **Costo:** el crecimiento del disco es un riesgo operativo activo, agravado por el volumen no
  dimensionado que el PRD reconoce. Exige monitorear espacio libre y definir una política de
  retención o compresión de imágenes; sin eso, el disco lleno deja de aceptar reportes.
- El uso de rutas relativas y un adaptador de almacenamiento aislado mantiene abierta la migración a
  object storage si el volumen real lo obliga, sin migración de datos en la base.
