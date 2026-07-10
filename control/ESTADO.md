# Estado — 2026-07-10

*EL HILO DEL PROYECTO. Se SOBRESCRIBE al cierre de cada sesión (la historia vive en BITACORA.md).
Máximo 60 líneas. Si la conversación se borrara, este archivo tiene que bastar para continuar.*

## Ahora mismo

- **En curso**: ninguna — T1-T4 cerradas, falta empezar T5.
- **Siguiente paso concreto**: delegar T5 "Scroll automático a velocidad fija" al `constructor`,
  según su alcance y Definición de Hecho en control/TAREAS.md.
- **Tareas cerradas desde la última limpieza**: 4 *(al llegar a ~10 toca pasada anti-deriva)*

## Qué funciona (verificado por el verificador)

*Smoke-list curada: las funcionalidades núcleo, máx. ~15 filas. El historial completo de
logros vive en las tareas cerradas de TAREAS.md con su evidencia — esas no se borran.*

| Funcionalidad | Verificada | Cómo se probó |
|---|---|---|
| Esqueleto de la app (3 zonas, módulos JS cargan) | 2026-07-10 | Servido local, Network 200 en todos los assets, consola con los 5 "cargado" |
| Activar cámara (`getUserMedia`) | 2026-07-10 (parcial) | Manejo de error sin cámara confirmado en navegador; el camino feliz (imagen en vivo) NO probado — sin cámara física en este entorno |
| Grabación con MediaRecorder | 2026-07-10 (parcial) | Revisión de código: mimeType con fallback, sin fuga de memoria, botón deshabilitado sin stream; grabación real NO probada — sin cámara física |
| Overlay de texto estático sobre cámara | 2026-07-10 | Revisión de código + cálculo de layout: zona de texto 25% del alto, guion de ejemplo excede con margen; `montarTexto()` expuesto para reuso |

## Bloqueos y decisiones pendientes

- **Pendiente de confirmar en hardware real** (no bloquea seguir construyendo, pero si antes de
  entregar la v1): el camino feliz de cámara/mic/grabación (ver imagen en vivo, `playsinline` real
  en Safari, grabar+reproducir+descargar un video) no se puede probar en este entorno porque no
  tiene cámara física. Falta un pase de verificación en un iPhone real (o navegador de escritorio
  con cámara) antes de dar la v1 por terminada.
- Herramientas de navegador interactivo (Claude Browser / extensión Chrome) fallaron a mitad de
  sesión (extensión desconectada) — T4 se verificó por revisión de código y `curl`. Reintentar
  con herramientas visuales en la siguiente tarea si vuelven a estar disponibles.

## Última sesión

2026-07-10 — instalación del sistema + plan (6 fases/11 tareas) + T1 a T4 implementadas y
verificadas (con las salvedades de arriba). Un agente constructor se cortó a mitad de T4 por
límite de sesión de Anthropic, pero había dejado el trabajo completo; se verificó igual.
