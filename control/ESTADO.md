# Estado — 2026-07-10

*EL HILO DEL PROYECTO. Se SOBRESCRIBE al cierre de cada sesión (la historia vive en BITACORA.md).
Máximo 60 líneas. Si la conversación se borrara, este archivo tiene que bastar para continuar.*

## Ahora mismo

- **En curso**: ninguna — T1-T14 implementadas. El usuario ha probado la app tres veces en su
  iPhone real y cada ronda de feedback se tradujo en una tarea. T14 (recalibración de voz, modal
  obligatorio de video, indicador de grabando visible) recién se implementó — incluye además una
  corrección de un bug real en la fórmula de mapeo nivel→velocidad que el constructor no había
  detectado (ver TAREAS.md T14 para el detalle).
- **Siguiente paso concreto**: pedirle al usuario que abra
  https://juandiegorodri.github.io/teleprompter-app/ en su iPhone y confirme los 3 puntos de T14,
  sobre todo si la velocidad por voz YA sigue el ritmo real al hablar (van dos rondas de
  calibración a ciegas sin micrófono real disponible en este entorno — puede necesitar un tercer
  ajuste si sigue sin sentirse bien). Confirmar también que el modal de resultado obliga a elegir
  Descargar/Descartar, y que el punto rojo de "grabando" se ve bien sobre el video.
- **Tareas cerradas desde la última limpieza**: 14 *(YA TOCA la pasada anti-deriva — pendiente hace
  varias tareas, hacerla en cuanto la app se estabilice)*

## Qué funciona (verificado por el verificador)

*Smoke-list curada: las funcionalidades núcleo, máx. ~15 filas. El historial completo de
logros vive en las tareas cerradas de TAREAS.md con su evidencia — esas no se borran.*

| Funcionalidad | Verificada | Cómo se probó |
|---|---|---|
| Cámara, grabación y descarga del video | 2026-07-10 | **CONFIRMADO POR EL USUARIO en iPhone real** |
| Flujo T12 (cámara habilita todo, botón grande grabar, config agrupada) | 2026-07-10 | **CONFIRMADO POR EL USUARIO**: "ya está funcionando muchísimo mejor" |
| T13 (texto superpuesto, preview en vivo, velocidad/lente configurables) | 2026-07-10 | Revisión de código — el usuario pasó directo a probar y reportar T14 sin confirmar T13 explícitamente; asumir pendiente de confirmación implícita |
| Publicación en GitHub Pages | 2026-07-10 | `https://juandiegorodri.github.io/teleprompter-app/`, se actualiza en cada push |
| Editor de guion con localStorage | 2026-07-10 | Revisión de código — no probado en vivo por el usuario aún |
| Manifest PWA + iconos + safe-areas | 2026-07-10 | JSON e iconos válidos; instalación a pantalla de inicio no confirmada aún |
| T14 (voz recalibrada 2ª vez + fix de fórmula, modal obligatorio, indicador rojo) | 2026-07-10 | Revisión de código exhaustiva, incluida corrección de un bug de fórmula — PENDIENTE de que el usuario lo pruebe |

## Bloqueos y decisiones pendientes

- **Pendiente de reconfirmación en iPhone real**: T14 (y T13, que no se confirmó explícitamente
  antes de que llegara el feedback de T14). Es el paso inmediato siguiente.
- **Riesgo conocido**: la detección de voz por energía de audio (RMS + umbrales) lleva dos rondas
  de calibración a ciegas sin micrófono real. Si en la próxima prueba sigue sin sentirse bien, el
  problema puede no ser de calibración sino de enfoque — considerar si vale la pena que el usuario
  comparta un valor de `nivel` real (con `console.log`) para calibrar con datos reales en vez de
  adivinar de nuevo.
- **Toca pasada anti-deriva** (14 tareas cerradas, viene arrastrándose desde T11): hacerla en
  cuanto la app se estabilice tras esta ronda de fixes — revisar MAPA.md especialmente, quedó
  desalineado desde el rediseño de layout de T13.
- Túnel de localtunnel usado en pruebas tempranas ya no es necesario — GitHub Pages es la URL
  estable de prueba/entrega.

## Última sesión

2026-07-10 — sesión muy larga: instalación del sistema + plan (11 tareas) + T1-T11 + publicación
en GitHub Pages + 3 rondas de prueba real del usuario en iPhone, cada una generando una tarea de
ajuste (T12 flujo simplificado, T13 diseño/texto sobre cámara, T14 recalibración de voz + modal +
indicador). Patrón establecido: usuario prueba en dispositivo real → reporta → se traduce a tarea
con DoD → constructor implementa → verificación por código (sin cámara/mic reales disponibles) →
push a GitHub Pages → usuario prueba de nuevo. Falta que confirme T14 (y T13).
