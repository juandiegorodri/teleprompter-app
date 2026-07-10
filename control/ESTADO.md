# Estado — 2026-07-10

*EL HILO DEL PROYECTO. Se SOBRESCRIBE al cierre de cada sesión (la historia vive en BITACORA.md).
Máximo 60 líneas. Si la conversación se borrara, este archivo tiene que bastar para continuar.*

## Ahora mismo

- **En curso**: ninguna — T1-T13 implementadas. El usuario confirmó en su iPhone que T12 (flujo
  simplificado) funciona mucho mejor: activar cámara habilita todo, botón grande de grabar,
  configuración agrupada. T13 (texto superpuesto sobre la cámara, preview en vivo en ajustes,
  velocidad y lente configurables) recién se implementó a partir de ese segundo feedback y está
  pendiente de que el usuario la pruebe en el dispositivo.
- **Siguiente paso concreto**: pedirle al usuario que abra
  https://juandiegorodri.github.io/teleprompter-app/ en su iPhone y confirme los 6 puntos de T13
  (texto legible superpuesto sobre el video, preview en vivo al mover los sliders de ajustes,
  slider de velocidad afecta el teleprompter real y persiste, se sigue combinando con la voz,
  selector de lente frontal/trasera funciona sin dejar cámaras huérfanas encendidas). Si algo
  falla, corregirlo. Si todo funciona, ya no quedan pendientes conocidos de la fase de diseño
  que el usuario pidió — el siguiente paso natural sería la pasada anti-deriva (13 tareas
  cerradas) y/o cerrar la sesión con un resumen para el usuario.
- **Tareas cerradas desde la última limpieza**: 13 *(YA TOCA la pasada anti-deriva)*

## Qué funciona (verificado por el verificador)

*Smoke-list curada: las funcionalidades núcleo, máx. ~15 filas. El historial completo de
logros vive en las tareas cerradas de TAREAS.md con su evidencia — esas no se borran.*

| Funcionalidad | Verificada | Cómo se probó |
|---|---|---|
| Cámara, grabación y descarga del video | 2026-07-10 | **CONFIRMADO POR EL USUARIO en iPhone real** |
| Flujo T12 (cámara habilita todo, botón grande grabar, config agrupada) | 2026-07-10 | **CONFIRMADO POR EL USUARIO**: "ya está funcionando muchísimo mejor" |
| Publicación en GitHub Pages | 2026-07-10 | `https://juandiegorodri.github.io/teleprompter-app/` responde 200, se actualiza en cada push |
| Editor de guion con localStorage | 2026-07-10 | Revisión de código — no probado en vivo por el usuario aún |
| Detección de voz (VAD) + enganche a velocidad, ON por defecto | 2026-07-10 | Confirmado indirectamente por el usuario (el modo voz mueve el texto) |
| Manifest PWA + iconos + safe-areas | 2026-07-10 | JSON e iconos válidos; instalación a pantalla de inicio no confirmada aún |
| T13: texto superpuesto + preview en vivo + velocidad/lente configurables | 2026-07-10 | Revisión de código exhaustiva — recién implementado, PENDIENTE de que el usuario lo pruebe en su iPhone |

## Bloqueos y decisiones pendientes

- **Pendiente de reconfirmación en iPhone real**: T13 se implementó a partir del feedback del
  usuario pero aún no la ha probado. Es el paso inmediato siguiente.
- **Toca pasada anti-deriva** (13 tareas cerradas): pendiente, hacerla después de que T13 quede
  confirmada y estable — revisar en particular si algún doc de control (MAPA.md especialmente)
  quedó desalineado tras el rediseño de layout de T13.
- No quedan bugs abiertos conocidos ni ítems pendientes explícitos de "fase de diseño" — T13 cubrió
  todo lo que el usuario había pedido dejar para después.
- Túnel de localtunnel usado en pruebas tempranas ya no es necesario — GitHub Pages es la URL
  estable de prueba/entrega desde la sesión anterior.

## Última sesión

2026-07-10 — sesión larga: instalación del sistema + plan (11 tareas) + T1-T11 implementadas +
publicación en GitHub Pages + primera prueba real del usuario (cámara/grabación/descarga
funcionando) + T12 (flujo simplificado, confirmado por el usuario como mucho mejor) + T13
(texto sobre cámara, preview en vivo, velocidad/lente configurables) a partir del segundo
feedback. Falta que el usuario reconfirme T13 en su dispositivo.
