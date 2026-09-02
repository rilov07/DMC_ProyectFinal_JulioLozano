# ADR 0002: Stack de `georeport-api` — NestJS sobre Node.js y TypeScript

## Estado

Aceptado

## Contexto

La [ADR-0001](0001-topologia-spa-angular-mas-api-propia.md) concentró toda la lógica de negocio en
un backend propio: autorización por rol, validación de reportes, consulta geoespacial de
duplicados, máquina de estados con historial inmutable, almacenamiento de evidencia, agregados del
dashboard y un proceso periódico de escalamiento por plazo vencido.

Las restricciones reales que pesan sobre la elección de lenguaje y framework son: un equipo de una
persona con plazo de curso, un frontend ya fijado en Angular y TypeScript, y un dominio con reglas
de transición explícitas que conviene expresar como servicios de aplicación testeables.

## Decisión

`georeport-api` se implementa en **NestJS sobre Node.js con TypeScript**, organizado en módulos por
dominio (reportes, validación, asignaciones, historial, notificaciones, dashboard, usuarios). El
proceso de escalamiento por plazo vencido se implementa con el scheduler de Nest
(`@nestjs/schedule`) dentro del mismo despliegue, no como componente separado.

## Alternativas consideradas

- **Spring Boot (Java)** — Era la opción más sólida para un dominio con reglas y transacciones:
  Hibernate Spatial habla PostGIS de forma nativa, el manejo transaccional es maduro y el scheduler
  viene incluido. Se descartó por el costo de contexto: introducir Java junto a un frontend Angular
  duplica el ecosistema que una sola persona debe sostener, y el peso ceremonial del framework no
  se justifica en un proyecto de este tamaño.
- **FastAPI (Python)** — Genuinamente viable y probablemente la más rápida de escribir: validación
  por Pydantic, documentación OpenAPI generada automáticamente y el mejor ecosistema geoespacial y
  de análisis de los tres. Se descartó porque introduce un tercer lenguaje en un proyecto que ya
  tiene TypeScript en el frontend y SQL en la base, sin un beneficio que compense esa dispersión.

## Consecuencias

- Un solo lenguaje en toda la aplicación: las interfaces del contrato de API (DTOs de reporte,
  incidencia, historial) pueden definirse una vez y consumirse tipadas desde Angular, eliminando
  una clase entera de errores de integración entre los dos componentes.
- La arquitectura de NestJS (módulos, inyección de dependencias, decoradores) es prácticamente la
  misma que la de Angular, así que el aprendizaje de un componente se transfiere al otro — una
  ventaja concreta para un equipo de una persona.
- El scheduler embebido evita un tercer despliegue solo para el job de escalamiento.
- **Costo:** el soporte geoespacial en el ecosistema Node es más delgado que en Java o Python. Las
  consultas de PostGIS (`ST_DWithin`, `ST_Within`, agregación por zona, mapa de calor) se
  escribirán como SQL explícito o con el query builder del ORM, no mediante abstracciones del
  ORM — lo que exige conocer PostGIS de verdad y hace esas consultas más difíciles de refactorizar.
- **Costo:** al vivir el scheduler dentro del mismo proceso de la API, escalar la API a varias
  instancias haría que el job de escalamiento se ejecutara varias veces. Mitigable con un candado
  en base de datos, pero es una deuda a pagar si el despliegue crece.
