# Estado — 2026-07-10

*EL HILO DEL PROYECTO. Se SOBRESCRIBE al cierre de cada sesión (la historia vive en BITACORA.md).
Máximo 60 líneas. Si la conversación se borrara, este archivo tiene que bastar para continuar.*

## Ahora mismo

- **En curso**: ninguna — T1-T8 cerradas (Fases 1 a 4 completas), falta empezar T9.
- **Siguiente paso concreto**: delegar T9 "Ajustes de tipografía y fondo del texto" al
  `constructor`, según su alcance y Definición de Hecho en control/TAREAS.md.
- **Tareas cerradas desde la última limpieza**: 8 *(al llegar a ~10 toca pasada anti-deriva)*

## Qué funciona (verificado por el verificador)

*Smoke-list curada: las funcionalidades núcleo, máx. ~15 filas. El historial completo de
logros vive en las tareas cerradas de TAREAS.md con su evidencia — esas no se borran.*

| Funcionalidad | Verificada | Cómo se probó |
|---|---|---|
| Esqueleto de la app (3 zonas, módulos JS cargan) | 2026-07-10 | Servido local, Network 200, consola con 5 "cargado" |
| Activar cámara (`getUserMedia`) | 2026-07-10 (parcial) | Manejo de error sin cámara confirmado en navegador; camino feliz NO probado — sin cámara física |
| Grabación con MediaRecorder | 2026-07-10 (parcial) | Revisión de código; grabación real NO probada — sin cámara física |
| Overlay de texto estático sobre cámara | 2026-07-10 | Revisión de código + cálculo de layout |
| Scroll automático (Play/Pausa/Reiniciar, delta-tiempo) | 2026-07-10 | Revisión de código — herramientas de navegador no disponibles en este tramo |
| Editor de guion con localStorage | 2026-07-10 | Revisión de código, sintaxis validada — flujo interactivo no probado en vivo |
| Detección de voz (VAD por energía, histéresis) | 2026-07-10 (parcial) | Revisión de código; audio real NO probado — sin micrófono físico |
| Enganche voz → velocidad del teleprompter | 2026-07-10 (parcial) | Revisión de código; ciclo real habla/silencio NO probado |

## Bloqueos y decisiones pendientes

- **Pendiente de confirmar en hardware real antes de cerrar la v1** (no bloquea seguir construyendo):
  todo el camino feliz de cámara/mic (ver imagen en vivo, grabar+reproducir+descargar, subir/bajar
  indicador de voz, ciclo habla→pausa→habla, aceleración perceptible) no se pudo probar en este
  entorno por falta de cámara/micrófono físicos. Falta un pase de verificación en iPhone real antes
  de dar la v1 por terminada — se le avisó al usuario desde el inicio de la sesión.
- Herramientas de navegador interactivo (Claude Browser / extensión Chrome) estuvieron caídas la
  mayor parte de esta sesión — la verificación de T4 a T8 se hizo por revisión de código, `node --check`
  y `curl`, no interactivamente. Reintentar herramientas visuales en la próxima sesión.
- **Bug abierto #1** (TAREAS.md, sección Bugs): activar "Modo voz" antes de activar detección de voz
  deja el scroll a la última velocidad conocida en vez de 0. Bajo impacto, no arreglado aún.

## Última sesión

2026-07-10 — instalación del sistema + plan (6 fases/11 tareas) + T1 a T8 implementadas y
verificadas (con las salvedades de arriba: sin hardware de cámara/mic real). Fases 1-4 completas.
Un agente constructor se cortó a mitad de T4 por límite de sesión de Anthropic, pero había dejado
el trabajo completo; se verificó igual. Faltan T9, T10 (Fase 5 — personalización) y T11 (Fase 6 — PWA).
