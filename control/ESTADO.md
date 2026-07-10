# Estado — 2026-07-10

*EL HILO DEL PROYECTO. Se SOBRESCRIBE al cierre de cada sesión (la historia vive en BITACORA.md).
Máximo 60 líneas. Si la conversación se borrara, este archivo tiene que bastar para continuar.*

## Ahora mismo

- **En curso**: ninguna — T1-T15b implementadas (T15a fue un fix directo de una línea, sin pasar
  por el enjambre). Cuarta ronda de feedback real del usuario: velocidad máxima insuficiente,
  grabación que se corta a los ~20s (video se congela, audio sigue), indicador de "grabando" activo
  sin grabar (arreglado directo), y calidad de cámara percibida como baja.
- **Siguiente paso concreto**: pedirle al usuario que abra
  https://juandiegorodri.github.io/teleprompter-app/ en su iPhone y confirme, en este orden de
  importancia: (1) si el indicador de grabando YA solo aparece grabando de verdad, (2) si grabar
  un video de más de 20-30 segundos ya NO se corta (la mitigación — timeslice + Screen Wake Lock —
  es la mejor posible sin poder reproducir el bug en este entorno; si persiste, el problema puede
  no ser de las dos causas asumidas y necesita más investigación dirigida), (3) si la velocidad
  máxima del slider ahora alcanza a sentirse "rápida" de verdad, (4) si la calidad de imagen mejoró
  con la resolución más alta pedida (aclarar al usuario que nunca va a igualar 100% la app nativa
  de Cámara — eso es una limitación de la Web API, no algo arreglable desde aquí).
- **Tareas cerradas desde la última limpieza**: 16 *(MUY atrasada — la pasada anti-deriva viene
  posponiéndose desde T11; hacerla en la próxima sesión sin más rondas de features encima)*

## Qué funciona (verificado por el verificador)

*Smoke-list curada: las funcionalidades núcleo, máx. ~15 filas. El historial completo de
logros vive en las tareas cerradas de TAREAS.md con su evidencia — esas no se borran.*

| Funcionalidad | Verificada | Cómo se probó |
|---|---|---|
| Cámara, grabación y descarga del video | 2026-07-10 | **CONFIRMADO POR EL USUARIO en iPhone real** (con el bug de corte a los ~20s, en investigación) |
| Flujo T12 (cámara habilita todo, botón grande grabar, config agrupada) | 2026-07-10 | **CONFIRMADO POR EL USUARIO** |
| T13 (texto superpuesto, preview en vivo, velocidad/lente configurables) | 2026-07-10 | Revisión de código — nunca confirmado explícitamente por el usuario, asumir pendiente |
| Publicación en GitHub Pages | 2026-07-10 | Se actualiza en cada push, confirmado repetidamente |
| Indicador de "grabando" solo visible al grabar (T15a) | 2026-07-10 | Bug de especificidad CSS encontrado y arreglado directo — no confirmado aún por el usuario |
| T14 (voz recalibrada, modal obligatorio, indicador rojo) | 2026-07-10 | El usuario probó y reportó 4 problemas nuevos (T15a/T15b) — no confirmó explícitamente si el modal/voz de T14 ya estaban bien |
| T15b (velocidad hasta 100px/s, timeslice+WakeLock para el corte, resolución 1080p) | 2026-07-10 | Revisión de código — PENDIENTE de que el usuario lo pruebe, en particular el corte de grabación |

## Bloqueos y decisiones pendientes

- **Pendiente de reconfirmación en iPhone real**: T13, T14 y T15 completas — el usuario viene
  reportando problemas nuevos antes de confirmar explícitamente que los anteriores ya funcionan.
  Conviene, en la próxima ronda, pedirle una confirmación explícita punto por punto en vez de
  asumir que lo no mencionado ya está bien.
- **Riesgo conocido — el más importante ahora mismo**: el corte de grabación a los ~20s es un bug
  serio (se pierde video) mitigado pero NO confirmado como resuelto. Si persiste tras T15b, elegir
  otra hipótesis (ej. límite de memoria de MediaRecorder en Safari con timeslice corto, o un
  problema del propio `getUserMedia`/`videoBitsPerSecond` sin especificar) y pedir al usuario un
  dato más específico (ej. duración exacta donde se corta, si varía).
- **Toca pasada anti-deriva** (16 tareas cerradas, MUY atrasada desde T11): debe hacerse apenas la
  app deje de recibir bugs nuevos — MAPA.md especialmente desalineado desde T13.
- Túnel de localtunnel ya no es necesario — GitHub Pages es la URL estable de prueba/entrega.

## Última sesión

2026-07-10 — sesión muy larga: instalación + plan (11 tareas) + T1-T11 + GitHub Pages + 4 rondas
de prueba real del usuario en iPhone, cada una generando tareas de ajuste (T12 flujo simplificado,
T13 diseño/texto sobre cámara, T14 voz+modal+indicador, T15a/T15b velocidad+corte de
grabación+calidad). Patrón establecido: usuario prueba → reporta → tarea con DoD → constructor
implementa → verificación por código (sin cámara/mic reales) → push → usuario prueba de nuevo.
Bug más serio pendiente de confirmar resuelto: corte de grabación a los ~20s.
