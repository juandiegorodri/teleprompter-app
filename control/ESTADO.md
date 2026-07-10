# Estado — 2026-07-10

*EL HILO DEL PROYECTO. Se SOBRESCRIBE al cierre de cada sesión (la historia vive en BITACORA.md).
Máximo 60 líneas. Si la conversación se borrara, este archivo tiene que bastar para continuar.*

## Ahora mismo

- **En curso**: ninguna — T1-T12 implementadas. La v1 se publicó en GitHub Pages y el usuario
  confirmó que la cámara/grabación/descarga funcionan de verdad en su iPhone. T12 (flujo
  simplificado + voz por defecto + velocidad más lenta) recién se implementó tras ese primer
  feedback y está pendiente de que el usuario la pruebe en el dispositivo.
- **Siguiente paso concreto**: pedirle al usuario que abra
  https://juandiegorodri.github.io/teleprompter-app/ en su iPhone y confirme los 6 puntos de T12
  (controles bloqueados hasta activar cámara, voz activada sin botón extra, teleprompter que solo
  se mueve al grabar, velocidad más lenta y legible, menú de configuración agrupado). Si algo
  falla, corregirlo antes de pasar a la fase de diseño (superponer texto/cámara, selector de
  lente, preview de tipografía, slider de velocidad — anotado en Ideas/futuro de TAREAS.md).
- **Tareas cerradas desde la última limpieza**: 12 *(YA TOCA la pasada anti-deriva)*

## Qué funciona (verificado por el verificador)

*Smoke-list curada: las funcionalidades núcleo, máx. ~15 filas. El historial completo de
logros vive en las tareas cerradas de TAREAS.md con su evidencia — esas no se borran.*

| Funcionalidad | Verificada | Cómo se probó |
|---|---|---|
| Cámara, grabación y descarga del video | 2026-07-10 | **CONFIRMADO POR EL USUARIO en iPhone real** vía GitHub Pages (HTTPS) |
| Teleprompter con scroll | 2026-07-10 | Confirmado por el usuario que se mueve; velocidad reportada como "muy rápida" — ajustada en T12, pendiente reconfirmar |
| Publicación en GitHub Pages | 2026-07-10 | `https://juandiegorodri.github.io/teleprompter-app/` responde 200 con el HTML correcto |
| Editor de guion con localStorage | 2026-07-10 | Revisión de código, sintaxis validada — no probado en vivo por el usuario aún |
| Detección de voz (VAD) + enganche a velocidad | 2026-07-10 | Revisión de código; el usuario confirmó indirectamente que el modo voz mueve el texto, pero reportó bugs de flujo — corregidos en T12 |
| Ajustes de tipografía/fondo + proporción cámara/texto | 2026-07-10 | Revisión de código — no probado en vivo por el usuario aún |
| Manifest PWA + iconos + safe-areas | 2026-07-10 | JSON e iconos válidos; instalación a pantalla de inicio no confirmada aún |
| T12: flujo simplificado (cámara habilita todo, grabar controla scroll, voz por defecto) | 2026-07-10 | Revisión de código exhaustiva — recién implementado, PENDIENTE de que el usuario lo pruebe en su iPhone |

## Bloqueos y decisiones pendientes

- **Pendiente de reconfirmación en iPhone real**: T12 se implementó a partir del feedback del
  usuario pero aún no la ha probado. Es el paso inmediato siguiente.
- **Toca pasada anti-deriva** (12 tareas cerradas): pendiente, hacerla después de que T12 quede
  confirmada y estable.
- **Bug abierto #1**: resuelto por diseño en T12 (ya no puede ocurrir el escenario que lo causaba).
- **Fase de diseño pendiente** (explícitamente pedida por el usuario para después): superponer
  texto sobre cámara, selector de lente frontal/trasera, preview en vivo de tipografía en ajustes,
  control de velocidad por defecto en el panel — todo detallado en Ideas/futuro de TAREAS.md.
- Túnel de localtunnel (`https://violet-donuts-yawn.loca.lt`) usado para pruebas tempranas ya no
  es necesario — se reemplazó por GitHub Pages como URL estable de prueba/entrega.

## Última sesión

2026-07-10 — sesión larga: instalación del sistema + plan (11 tareas) + T1-T11 implementadas +
publicación en GitHub Pages (`juandiegorodri/teleprompter-app`, Pages sirviendo `main`) + primera
prueba real del usuario en su iPhone (cámara/grabación/descarga confirmados funcionando) + T12
implementada a partir de ese feedback (flujo simplificado, voz por defecto, velocidad más lenta).
Falta que el usuario reconfirme T12 en su dispositivo.
