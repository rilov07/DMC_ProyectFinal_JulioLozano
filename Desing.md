---
name: GeoReport Vial Design System
base: Industry (_ds/industry-da083dbf-336c-41f3-b9b3-a5bb89ed8080/)
colors:
  bg: '#f2f2f3'
  surface: '#e9e9ea'
  text: '#1d1f20'
  accent: '#5980a6'
  divider: 'rgba(29,31,32,0.16)'
  neutral-100: '#f5f5f8'
  neutral-200: '#e7e7ea'
  neutral-300: '#d4d4d7'
  neutral-400: '#b7b7ba'
  neutral-500: '#98989b'
  neutral-600: '#7a7a7d'
  neutral-700: '#5d5d60'
  neutral-800: '#424244'
  neutral-900: '#2b2b2d'
  accent-100: '#eef6ff'
  accent-200: '#d6ebff'
  accent-300: '#b5d9fd'
  accent-400: '#94bce3'
  accent-500: '#749dc4'
  accent-600: '#597ea3'
  accent-700: '#416180'
  accent-800: '#2c455d'
  accent-900: '#1d2d3d'
typography:
  display-xl:
    fontFamily: Barlow Condensed
    fontSize: 30px
    fontWeight: '600'
    lineHeight: '1.1'
    letterSpacing: 0.02em
  headline-lg:
    fontFamily: Barlow Condensed
    fontSize: 20px
    fontWeight: '600'
    lineHeight: '1.2'
    letterSpacing: 0.04em
  headline-md:
    fontFamily: Barlow Condensed
    fontSize: 15px
    fontWeight: '600'
    lineHeight: '1.2'
    letterSpacing: 0.06em
    textTransform: uppercase
  headline-sm:
    fontFamily: Barlow Condensed
    fontSize: 13px
    fontWeight: '600'
    lineHeight: '1.2'
    letterSpacing: 0.06em
    textTransform: uppercase
  body-lg:
    fontFamily: Barlow
    fontSize: 14px
    fontWeight: '400'
    lineHeight: '1.5'
  body-md:
    fontFamily: Barlow
    fontSize: 12px
    fontWeight: '400'
    lineHeight: '1.45'
  body-sm:
    fontFamily: Barlow
    fontSize: 11px
    fontWeight: '400'
    lineHeight: '1.4'
  label-mono:
    fontFamily: ui-monospace
    fontSize: 10px
    fontWeight: '400'
    lineHeight: '1'
    letterSpacing: 0.06em
    textTransform: uppercase
  data-tabular:
    fontFamily: ui-monospace
    fontSize: 9.5px
    fontWeight: '400'
    lineHeight: '1'
spacing:
  unit: 3.4px
  xs: 3.4px
  sm: 6.8px
  md: 10.2px
  lg: 13.6px
  xl: 20.4px
  xxl: 27.2px
  gutter: 16px
  touch-target-min: 44px
radius:
  all: 0px
---

## Brand & Style

GeoReport Vial es una herramienta operativa de infraestructura vial, no una aplicación de
consumo. El sistema visual es **Industry**: un wireframe técnico —acero sobre fondo claro,
Barlow Condensed sobre Barlow, malla modular, y tarjetas, figuras y botones tratados como
objetos de plano: esquina recta, borde hairline y marcas de registro "+" en las esquinas.

La narrativa visual viene del plano de ingeniería civil y de la señalización vial. Sirve a
tres audiencias que no comparten contexto de uso: un ciudadano que reporta desde la calle
en menos de dos minutos, un validador que revisa decenas de reportes al día en escritorio,
y una cuadrilla que actualiza estados con guantes puestos.

Atributos clave:
- **Precisión sin decoración:** el dibujo de línea comunica que cada elemento es un dato,
  no un adorno.
- **Alta densidad de información:** mallas sistemáticas que soportan datos geoespaciales
  sin fatiga visual.
- **Un solo punto de énfasis:** el acento acero se reserva para acción y estado; nada más
  compite por atención.

## Colors

Esquema monocromo: un fondo claro (`--color-bg` #f2f2f3), tinta #1d1f20 y un único acento
acero #5980a6. Cada rol lleva una rampa 100–900 generada en OKLCH sobre la misma escala
perceptual de luminosidad.

- **Acento (acero):** acción primaria, marcador de mapa, estado activo, fila seleccionada.
  Es el único objeto sólido de cada vista.
- **Rampa acento 100–300:** rellenos tintados, avisos, extremo bajo del mapa de calor.
- **Rampa acento 700–900:** texto sobre tintados, extremo alto del mapa de calor. Todo
  texto de párrafo en acento usa `--color-accent-700`, no el acento base.
- **Rampa neutra:** bordes, divisores, placeholders y estados deshabilitados (45% opacidad).
- **Sin color categórico:** las series del dashboard se diferencian por paso de rampa, no
  por matiz. No hay verde de "resuelto" ni rojo de "crítico"; la urgencia se comunica con
  peso de borde y etiqueta textual.
- **Contraste:** la pareja acento-fondo está calibrada a 3:1 — suficiente para iconos,
  texto grande y cromo de interfaz, no para copy.

## Typography

- **Barlow Condensed (títulos):** cabeceras, botones y las cifras grandes del dashboard.
  Condensada, en mayúsculas y con tracking abierto a partir de 15px, imita el rotulado de
  documento técnico.
- **Barlow (cuerpo):** copy, campos de formulario, celdas de tabla.
- **Monoespaciada (metadatos):** folios, coordenadas, marcas de tiempo, distancias,
  etiquetas de eje y de columna. Es la señal de "esto es un dato del sistema, no una
  redacción humana".
- **Cifras tabulares:** listas, historial y dashboard alinean números en columna para
  permitir barrido vertical.

## Layout & Spacing

Malla modular de celdas iguales con ritmo horizontal y vertical visible.

- **Base 3.4px:** el sistema trae densidad 0.85× horneada en la escala `--space-*`. Todo
  espaciado sale de esas variables.
- **Escritorio:** patrón de tres zonas — rail de filtros y colas · canvas central (tabla o
  mapa) · panel de detalle. Divisores hairline entre zonas, sin sombra ni relleno.
- **Móvil:** columna única, 12px de margen lateral, acción primaria fija al borde inferior.
- **Objetivos táctiles:** mínimo 44px de alto en móvil.
- **Sin scroll horizontal desde 360px.** En móvil las tres zonas de escritorio colapsan a
  lista + hoja inferior de detalle.

## Elevation & Depth

La profundidad se comunica por estructura, no por sombra.

- **Eje Z por borde:** los elementos base llevan borde hairline (`--color-divider`); los
  activos o seleccionados suben a 1.5px en acento.
- **Capas tonales:** fondo de aplicación `--color-bg`; superficies de pantalla en blanco;
  bloques tintados en `--color-accent-100`.
- **Modales:** único caso de elevación real, con `--shadow-lg` sobre backdrop, conservando
  esquina recta y marcas de registro.
- **Realce de urgencia:** los estados que exigen acción (escalamiento, duplicado detectado)
  usan fondo `--color-accent-100` con borde 1.5px en acento, no color de alarma.

## Shapes

Geometría estrictamente **recta (0px)**. Botones, tarjetas, campos, casillas, etiquetas de
estado y controles de mapa son rectángulos. Ninguna figura se redondea ni se recorta.

Todo marco lleva `.blueprint` más sus cuatro marcas `<i class="corner tl/tr/bl/br">`. Las
marcas no se omiten: son la firma del sistema.

## Components

### Buttons
- **Primary:** relleno sólido `--color-accent`, texto blanco, Barlow Condensed en
  mayúsculas con tracking. Es el único objeto sólido de la vista.
- **Secondary:** transparente, borde hairline, misma tipografía.
- **Estados:** hover `--color-accent-600`; foco `outline: 2px solid var(--color-accent)`
  con `outline-offset: 2px`; deshabilitado a 45% de opacidad.

### Incident Cards
Contenedor principal de datos en listas y bandejas. Contienen:
- Folio y tipo en una línea, en Barlow semibold.
- Fila de metadatos en `label-mono`: zona, distancia, antigüedad, plazo.
- Etiqueta de estado o de señal alineada a la derecha.
- Borde hairline; borde 1.5px en acento cuando están seleccionadas.

### Indicators & Badges (Status)
Bloques rectangulares con borde hairline y texto en `data-tabular`. Sin relleno salvo el
caso de acento activo. Vocabulario cerrado: `VALIDADO`, `ASIGNADO`, `EN PROCESO`,
`RESUELTO`, `DESCARTADO`, `DUPLICADO?`, `VENCIDO`, `FUERA ÁMB.`, `ALTA` / `MEDIA` / `BAJA`.

### Input Fields
Pila etiqueta-campo: etiqueta en `label-mono` sobre caja blanca con borde hairline. En
foco el borde pasa a acento y aparece el anillo de 2px. Los campos obligatorios se marcan
con asterisco en la etiqueta.

### State Machine (control de estados)
Componente propio del producto, en dos presentaciones:
- **Horizontal (detalle):** cinco nodos unidos por línea; cumplidos en acento sólido,
  pendientes en contorno neutro.
- **Vertical (seguimiento del ciudadano):** los mismos nodos con marca de tiempo.

### Interactive Maps
Base de mapa neutra, sin color de marca. Marcadores como círculos de 1.5px en acento con
relleno `--color-accent-200`. Radio de búsqueda de duplicados como círculo punteado.
Polígono de ámbito geográfico punteado en acento. Los controles flotantes son cuadrados
blancos con borde hairline, sin redondeo. El mapa de calor interpola de `--color-accent-200`
a `--color-accent-700`.

### Evidence Upload
Zona de arrastre con borde punteado hairline y un "+" centrado. Las miniaturas cargadas son
cuadradas con borde hairline; una carga incompleta muestra el porcentaje sobre la miniatura
y la etiqueta `PENDIENTE`. El copy de instrucción va en `label-mono`.

---

## Inventario de pantallas

| # | Pantalla | Rol | Dispositivo | Wireframe |
| --- | --- | --- | --- | --- |
| 01 | Mapa / inicio | Ciudadano | Móvil | 1a |
| 02 | Formulario de reporte (3 pasos) | Ciudadano | Móvil | 1a |
| 03 | Confirmación y seguimiento | Ciudadano | Móvil | 1a |
| E1–E5 | Casos borde del reporte | Ciudadano | Móvil | 1b |
| 04 | Bandeja de validación | Validador | Escritorio | 1c |
| 05 | Comparador / agrupación de duplicados | Validador | Escritorio | 1d |
| 06 | Detalle de incidencia | Validador · Supervisor | Escritorio | 1e |
| 07 | Mis asignaciones | Cuadrilla | Móvil | 1f |
| 08 | Cambio de estado con evidencia | Cuadrilla | Móvil | 1f |
| 09 | Notificaciones y escalamiento | Cuadrilla · Supervisor | Móvil | 1f |
| 10 | Dashboard de indicadores | Supervisor | Escritorio | 1g |

## Modelo de estados

```
reportado → validado → asignado → en proceso → resuelto
     ↘ descartado (rechazado · duplicado · fuera de ámbito)
```

Cada transición escribe una entrada de historial con usuario, fecha-hora, estado anterior,
estado nuevo y comentario opcional. El historial es de solo lectura. `resuelto` exige al
menos una foto de evidencia de cierre; `descartado` exige causal.

## Decisiones de flujo

| Pantalla | Decisión |
| --- | --- |
| 01 | El mapa es el estado por defecto, no un campo del formulario: la georreferenciación es el eje del producto. |
| 02 | Tres pasos con progreso, tipo → evidencia → ubicación. Solo tipo y ubicación son obligatorios; la foto nunca bloquea el envío. |
| 03 | Folio grande y citable, con la línea de estados mostrando qué sigue. |
| E1 | Sin GPS: marcador punteado al centro y fijación manual. El reporte nunca se bloquea. |
| E2 | Foto sin subir: evidencia etiquetada `PENDIENTE`, reporte guardado igual. |
| E3 | Duplicado en origen: se muestran los cercanos del mismo tipo; la respuesta del ciudadano es una señal, no una decisión. |
| E4 | Fuera de ámbito: se dibuja el polígono, se permite enviar y llega marcado a la bandeja. |
| E5 | Sin conexión: borrador local, formulario atenuado, descartar o reintentar. |
| 04 | La columna SEÑALES concentra los avisos automáticos para priorizar sin abrir cada reporte. Acciones en lote. Cola explícita de vencidos >48 h. |
| 05 | Radio y ventana de tiempo ajustables desde la propia vista, por el riesgo de falsos positivos. Al agrupar, un solo responsable. |
| 06 | Asignación exige responsable, prioridad y plazo juntos: el plazo es lo que dispara el escalamiento. |
| 07–08 | Cambio de estado como tres opciones grandes, no desplegable. Evidencia de cierre obligatoria y anunciada antes de intentarlo. |
| 09 | Solo notificaciones internas; el PRD excluye avisos masivos a la ciudadanía. |
| 10 | Marca de actualización visible para hacer legible el criterio de latencia <5 min. |

## Pendientes antes de alta fidelidad

1. Confirmar el ámbito geográfico exacto y si habrá multi-zona desde el día uno.
2. Definir el proveedor de mapas — condiciona el estilo del mapa base y sus controles.
3. Validar los umbrales de duplicado (radio y ventana) con el equipo operativo.
4. Definir el plazo por tipo de incidencia que dispara el escalamiento en 09.
5. Confirmar si el ciudadano se autentica o reporta de forma anónima; hoy 06 asume anónimo.
6. Diseñar la administración de usuarios y roles, no cubierta en esta ronda.
