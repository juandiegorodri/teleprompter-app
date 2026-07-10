# Estado — 2026-07-10

*EL HILO DEL PROYECTO. Se SOBRESCRIBE al cierre de cada sesión (la historia vive en BITACORA.md).
Máximo 60 líneas. Si la conversación se borrara, este archivo tiene que bastar para continuar.*

## Ahora mismo

- **En curso**: ninguna — las 11 tareas de la v1 (T1-T11) están implementadas y verificadas
  (por revisión de código, no visualmente — ver bloqueo abajo).
- **Siguiente paso concreto**: hacer un pase de verificación visual/funcional en un iPhone real
  (o al menos un navegador de escritorio con cámara/micrófono) sirviendo la carpeta con
  `npx serve .` y accediendo por HTTPS (ver CLAUDE.md, sección Comandos). Repasar uno por uno los
  ítems de TAREAS.md marcados "PENDIENTE" o "(código revisado, no probado en vivo)" y confirmarlos
  o corregir lo que falle. Empezar por T2/T3 (cámara/grabación) y T11 (instalación PWA), que son
  los más nuevos/riesgosos de probar sin hardware.
- **Tareas cerradas desde la última limpieza**: 11 *(YA TOCA la pasada anti-deriva — ver Bloqueos)*

## Qué funciona (verificado por el verificador)

*Smoke-list curada: las funcionalidades núcleo, máx. ~15 filas. El historial completo de
logros vive en las tareas cerradas de TAREAS.md con su evidencia — esas no se borran.*

| Funcionalidad | Verificada | Cómo se probó |
|---|---|---|
| Esqueleto de la app (3 zonas, módulos JS cargan) | 2026-07-10 | Servido local, Network 200, consola con 5 "cargado" — CONFIRMADO EN VIVO |
| Activar cámara (`getUserMedia`) | 2026-07-10 | Manejo de error confirmado en vivo; camino feliz (imagen real) solo por código — sin cámara física en este entorno |
| Grabación con MediaRecorder | 2026-07-10 | Solo revisión de código — sin cámara física |
| Overlay de texto estático + scroll automático | 2026-07-10 | Revisión de código + cálculo de layout |
| Editor de guion con localStorage | 2026-07-10 | Revisión de código, sintaxis validada |
| Detección de voz (VAD) + enganche a velocidad | 2026-07-10 | Revisión de código — sin micrófono físico |
| Ajustes de tipografía/fondo + proporción cámara/texto | 2026-07-10 | Revisión de código, variables CSS confirmadas por grep |
| Manifest PWA + iconos + safe-areas | 2026-07-10 | JSON e iconos válidos confirmados; instalación real requiere iPhone |

## Bloqueos y decisiones pendientes

- **BLOQUEO PRINCIPAL — falta el pase de verificación en hardware real.** Todo T1-T11 se implementó
  y se revisó a fondo por código, pero este entorno de desarrollo no tiene cámara ni micrófono
  físicos, y las herramientas de navegador interactivo (Claude Browser / extensión Chrome)
  estuvieron caídas la mayor parte de la sesión. Ningún camino feliz de cámara/mic/grabación/voz/
  instalación PWA se confirmó viendo la app funcionar de verdad. Antes de considerar la v1
  realmente terminada hace falta: abrir la app en un iPhone (vía túnel HTTPS, ver CLAUDE.md) y
  recorrer manualmente cada flujo.
- **Toca pasada anti-deriva** (11 tareas cerradas desde la instalación, ≥10 activa el aviso): en la
  próxima sesión, después del pase de verificación en hardware real, revisar código muerto,
  duplicados, y si algún doc de control quedó desalineado.
- **Bug abierto #1** (TAREAS.md, sección Bugs): activar "Modo voz" antes de activar detección de
  voz deja el scroll a la última velocidad conocida en vez de 0. Bajo impacto, no arreglado.

## Última sesión

2026-07-10 — sesión larga: instalación del sistema + plan (6 fases/11 tareas) + T1 a T11
implementadas y "verificadas" con la salvedad importante de que casi todo fue por revisión de
código (sin cámara/mic físicos en el entorno, y con las herramientas de navegador interactivo
caídas gran parte del tiempo). La v1 está funcionalmente completa en código; falta la confirmación
en un dispositivo real antes de darla por entregada.
