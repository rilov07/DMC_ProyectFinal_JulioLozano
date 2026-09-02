# ADR 0009: Contrato REST documentado con OpenAPI y cliente Angular generado

## Estado

Aceptado

## Contexto

La [ADR-0001](0001-topologia-spa-angular-mas-api-propia.md) partió el sistema en dos componentes
desplegables, lo que introduce una frontera de red entre la SPA Angular y `georeport-api`. Esa
frontera necesita un contrato explícito: qué endpoints existen, qué forma tienen los DTOs de
reporte, incidencia, historial y agregados del dashboard, y qué códigos de error devuelve cada
operación.

El riesgo concreto de un contrato tácito es que el frontend y el backend se desincronicen en
silencio y el error aparezca en tiempo de ejecución, en producción, y no al compilar. Con un solo
autor sosteniendo ambos lados, ese riesgo es alto: nadie más va a notar la discrepancia.

Ambos componentes están en TypeScript ([ADR-0002](0002-stack-nestjs-typescript.md)), lo que abre la
posibilidad de compartir tipos.

## Decisión

El contrato es **REST sobre HTTP/JSON**, con `georeport-api` como dueño único. NestJS genera el
esquema **OpenAPI** a partir de los DTOs y decoradores del propio código
(`@nestjs/swagger`), y desde ese esquema se **genera el cliente tipado que consume Angular**.

El esquema OpenAPI es un artefacto versionado del repositorio: un cambio en un DTO del backend se
propaga al cliente generado y rompe la compilación del frontend si dejó de ser compatible.

Los errores se devuelven con un cuerpo uniforme (código de dominio, mensaje legible y detalle de
validación cuando aplique), no como texto libre, para que el frontend pueda decidir qué mostrar sin
interpretar cadenas.

## Alternativas consideradas

- **REST con una librería de tipos compartida en un monorepo** — Viable y más directa: sin paso de
  generación, los DTOs se definen una vez y ambos lados los importan. Se descartó porque obliga a
  adoptar un monorepo con su propia configuración de build, y porque el contrato existiría solo
  como código TypeScript: no habría documentación navegable ni una descripción del API consumible
  por herramientas o por un revisor externo, algo valioso para un proyecto que debe sustentarse
  ante terceros.
- **GraphQL** — Genuinamente atractivo aquí, porque las pantallas del Design.md piden formas muy
  distintas de los mismos datos: tarjeta ligera en la bandeja de validación (04), detalle completo
  con historial (06), agregados y series del dashboard (10). GraphQL habría evitado endpoints a
  medida para cada una. Se descartó por desproporción: añade una capa de resolvers, complica la
  caché HTTP, no maneja bien la subida de archivos —central en este producto— y exige controlar el
  costo de consultas anidadas, todo para un frontend único bajo el mismo control.

## Consecuencias

- La desincronización entre componentes se detecta al compilar, no en producción, que es la única
  garantía práctica cuando una sola persona mantiene ambos lados de la frontera.
- El esquema OpenAPI documenta el API sin esfuerzo adicional y sin riesgo de quedar desactualizado,
  porque se deriva del código que realmente se ejecuta.
- REST convive naturalmente con el resto de decisiones: la cookie `httpOnly` de la
  [ADR-0007](0007-autenticacion-y-autorizacion.md), el endpoint de descarga de imágenes de la
  [ADR-0008](0008-evidencia-en-sistema-de-archivos.md) y el polling del dashboard aprovechan
  semántica y caché HTTP estándar.
- **Costo:** hay un paso de generación en el build que hay que ejecutar y no olvidar. Un cliente
  generado desactualizado da una falsa sensación de seguridad, así que la generación debe estar
  automatizada, no ser un comando manual.
- **Costo:** al no compartir tipos directamente, el mismo concepto se define dos veces (DTO de Nest
  y modelo generado en Angular). Son equivalentes por construcción, pero el código generado no
  debe editarse a mano y eso hay que respetarlo.
- **Costo:** REST obliga a diseñar endpoints específicos para las necesidades de cada pantalla
  (bandeja, detalle, agregados del dashboard) en vez de dejar que el cliente componga la consulta.
  Es trabajo explícito de diseño de API que GraphQL habría evitado.
