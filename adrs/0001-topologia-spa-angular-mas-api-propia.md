# ADR 0001: Topología de dos componentes — SPA Angular + API propia

## Estado

Aceptado

## Contexto

El PRD exige una única plataforma web responsiva que cubra cuatro contextos de uso muy distintos
(ciudadano en la calle, validador en escritorio, cuadrilla en campo, supervisor en dashboard) con
roles diferenciados, historial de auditoría, detección de duplicados por cercanía geográfica y
ventana de tiempo, y un dashboard con latencia de actualización menor a 5 minutos.

El Design.md convierte varias de esas exigencias en reglas de dominio duras, no en configuración de
interfaz: el estado `resuelto` exige al menos una foto de evidencia de cierre, `descartado` exige
causal, y el plazo asignado a una incidencia es lo que dispara el escalamiento. Toda transición
escribe una entrada de historial de solo lectura.

El usuario fijó dos restricciones de partida: **Angular** como framework de frontend y **Leaflet
con mapas libres (OpenStreetMap)** para la georreferenciación. Leaflet es una librería de cliente y
no condiciona la arquitectura de servidor; Angular sí, porque es un framework de SPA con su propio
build y su propio servidor de estáticos, lo que descarta un monolito full-stack tipo Next.js donde
UI y API comparten proceso.

El equipo es de una persona con un plazo de curso.

## Decisión

El sistema se construye como **dos componentes desplegables**:

1. **`georeport-web`** — SPA en Angular con Leaflet/OpenStreetMap. Responsabilidad: interfaz de los
   cuatro roles, dibujo del mapa (marcadores, radio de duplicados, polígono de ámbito, mapa de
   calor), captura del formulario y borrador local offline. No contiene reglas de negocio: no
   decide qué es duplicado, ni qué transición de estado es válida.
2. **`georeport-api`** — API propia con base de datos PostgreSQL + PostGIS. Responsabilidad:
   autenticación y autorización por rol, validación de reportes, consulta geoespacial de
   duplicados, máquina de estados con escritura del historial, almacenamiento de evidencia
   fotográfica, agregados del dashboard y el proceso periódico de escalamiento por plazo vencido.

La lógica de negocio vive íntegramente en `georeport-api`. El frontend es un cliente sin autoridad:
cualquier regla que aplique en el cliente (deshabilitar un botón, exigir una foto) es una
comodidad de interfaz que la API vuelve a verificar.

## Alternativas consideradas

- **Monolito full-stack (Next.js con API routes)** — Era la opción de menor fricción para un equipo
  de una persona: un solo despliegue, tipos compartidos entre UI y servidor, sin CORS. Se descartó
  porque el usuario eligió Angular como framework de frontend, y Angular no cumple el rol de
  servidor de aplicación que hace viable esa topología.
- **Angular + BaaS (Supabase) sin backend propio** — Genuinamente viable: Supabase aporta
  PostgreSQL con PostGIS, autenticación, almacenamiento de archivos y autorización por Row Level
  Security, lo que habría eliminado casi todo el trabajo de infraestructura y acelerado la entrega.
  Se descartó porque el peso de este proyecto está en reglas de dominio (transiciones válidas,
  evidencia obligatoria al resolver, causal obligatoria al descartar, agrupación de duplicados,
  escalamiento por plazo) que en ese modelo terminan repartidas entre el cliente Angular y
  políticas SQL o Edge Functions, quedando difíciles de testear y de auditar.
- **Híbrido: API propia usando Supabase solo como Postgres gestionado y Storage** — Conservaba el
  dominio centralizado y evitaba montar infraestructura. Se descartó por preferencia del usuario de
  no depender de un proveedor gestionado para la persistencia.

## Consecuencias

- La lógica de dominio queda en un solo lugar, en código versionado y testeable con pruebas
  unitarias, lo que permite demostrar el cumplimiento de los criterios del PRD sin depender del
  comportamiento del cliente.
- Un cliente comprometido o un navegador con JavaScript modificado no puede saltarse una regla de
  negocio, porque la autoridad no está en el frontend.
- **Costo:** hay dos despliegues, dos configuraciones y una frontera de red entre ellos. Aparecen
  CORS, manejo de tokens en el cliente y versionado del contrato de API, todo a cargo de una sola
  persona.
- **Costo:** se asume trabajo de infraestructura que el BaaS regalaba — autenticación, gestión de
  usuarios, almacenamiento de fotografías y el runner del proceso de escalamiento — y ese trabajo
  compite por el tiempo del plazo del curso.
- El uso de Leaflet con OpenStreetMap elimina el costo, la cuota y la dependencia contractual de un
  proveedor de mapas comercial, y resuelve el pendiente #2 del Design.md. A cambio, funciones que
  los SDK comerciales traen incluidas (geocodificación de direcciones, autocompletado de lugares)
  no vienen de fábrica y exigirían un servicio adicional si el producto llegara a necesitarlas.
