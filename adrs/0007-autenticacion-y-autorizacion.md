# ADR 0007: Autenticación de roles internos con JWT en cookie `httpOnly`

## Estado

Aceptado

## Contexto

El PRD deja el mecanismo de autenticación explícitamente sin definir: "Se asume que existirá un
proceso (manual o mediante invitación) para dar de alta a los usuarios con rol de validador,
responsable y supervisor; no se define aquí el mecanismo de autenticación". El Design.md lo repite
como pendiente #6: la administración de usuarios y roles no fue cubierta en esa ronda de diseño.

La [ADR-0005](0005-reporte-anonimo-con-contacto-opcional.md) ya resolvió que el ciudadano no se
autentica, así que esta decisión cubre únicamente los tres roles internos: **validador**,
**responsable/cuadrilla** y **supervisor**. Son pocos usuarios, dados de alta por un administrador,
que manipulan datos operativos de una entidad pública.

La [ADR-0001](0001-topologia-spa-angular-mas-api-propia.md) fijó una SPA Angular servida desde un
origen distinto al de la API, lo que convierte el transporte de la credencial en una decisión con
consecuencias de seguridad reales.

## Decisión

La API emite un **JWT firmado, entregado en una cookie `httpOnly`, `Secure` y `SameSite=Lax`**, tras
un login de usuario y contraseña contra la tabla de usuarios propia (contraseñas con `bcrypt` o
`argon2`). El token lleva el identificador de usuario y su rol.

La autorización se aplica **en la API**, con guards de NestJS por rol sobre cada endpoint. El
frontend usa el rol solo para decidir qué mostrar; nunca para decidir qué se permite. El alta de
usuarios internos es un proceso administrativo (semilla inicial más creación por un usuario
administrador), no un registro público.

El ciudadano no envía credencial alguna: los endpoints de creación y consulta de reporte por folio
son públicos.

## Alternativas consideradas

- **JWT en almacenamiento del cliente con cabecera `Authorization`** — La opción más simple con
  Angular: un `HttpInterceptor` breve, sin cookies, sin CORS con credenciales y sin CSRF. Se
  descartó porque el token queda legible desde JavaScript, de modo que cualquier vulnerabilidad
  XSS en la SPA — incluida una introducida por una dependencia de terceros — entrega credenciales
  válidas de un rol municipal a un atacante. Para datos operativos de una entidad pública, ese
  riesgo no compensa la comodidad.
- **Proveedor de identidad externo (Keycloak, Auth0)** — Genuinamente atractivo porque resolvería de
  fábrica justo lo que el Design.md dejó pendiente: gestión de usuarios, recuperación de
  contraseña, políticas de contraseña y MFA. Se descartó por desproporción: desplegar, configurar y
  mantener un servidor de identidad completo para tres roles y un puñado de usuarios añade más
  complejidad operativa de la que ahorra en un proyecto sostenido por una persona.

## Consecuencias

- El token de sesión es inalcanzable para el JavaScript de la página, lo que neutraliza el vector de
  robo de credenciales más probable en una SPA.
- La autorización vive en la API junto al resto del dominio (coherente con la ADR-0001), así que las
  reglas de rol se pueden probar con pruebas de integración sobre los endpoints, no confiando en la
  interfaz.
- El navegador adjunta la cookie automáticamente, así que el frontend no gestiona ni renueva tokens
  a mano.
- **Costo:** aparece exposición a CSRF, que el esquema de cabecera no tenía. Se mitiga con
  `SameSite=Lax` más un token anti-CSRF en las operaciones que cambian estado, y esa mitigación hay
  que implementarla y no olvidarla.
- **Costo:** el desarrollo local se complica. Frontend y API corren en puertos distintos, así que
  la API debe habilitar CORS con `credentials: true` y origen explícito, y `Secure` obliga a HTTPS
  o a una excepción documentada para el entorno local.
- **Costo:** al no usar un proveedor externo, todo lo que el Design.md dejó pendiente en el #6
  —alta de usuarios, cambio y recuperación de contraseña, desactivación— es código propio por
  escribir. Se asume conscientemente y queda como alcance del módulo de administración.
