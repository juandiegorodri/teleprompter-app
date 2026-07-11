# Estado — 2026-07-10

*EL HILO DEL PROYECTO. Se SOBRESCRIBE al cierre de cada sesión (la historia vive en BITACORA.md).
Máximo 60 líneas. Si la conversación se borrara, este archivo tiene que bastar para continuar.*

## Ahora mismo

- **En curso**: ninguna. Dos productos completos en este repo:
  1. **Web app** (T1-T15b): publicada en GitHub Pages, con 4 rondas de feedback real del usuario
     ya incorporadas. Bug pendiente sin confirmar resuelto: corte de grabación a los ~20s (mitigado
     con timeslice+WakeLock, no confirmado por el usuario).
  2. **App nativa iOS "TelepromtCam"** (T16-T27, Fases 11-20): recién completada de punta a punta
     en esta misma sesión — SwiftUI + AVFoundation, cámara con calidad/fps/lente configurables,
     teleprompter superpuesto con scroll por delta de tiempo, voz por AVAudioEngine (con la lección
     del bug de mapeo nivel→factor de la web aplicada desde el diseño), editor, flujo de grabación
     con modal Guardar en Fotos/Descartar, ícono + launch screen, metadata completa de App Store
     Connect + política de privacidad, y una auditoría final (T27) contra las Apple App Review
     Guidelines — sin hallazgos de falla. Compila limpio (`xcodebuild` → `BUILD SUCCEEDED`, 0
     warnings) y arranca sin crash en simulador (smoke-launch confirmado).
- **Siguiente paso concreto**: el usuario debe abrir `ios/TelepromtCam.xcodeproj` en Xcode y seguir
  la "Checklist final — lo que le queda al USUARIO" al final de TAREAS.md (8 pasos: signing con su
  Team ID, probar en simulador/iPhone real, crear la app en App Store Connect con `ios/AppStore/
  metadata.md`, screenshots, cuestionario de privacidad con `resumen-privacidad-apple.md`, archivar
  y subir el build, enviar a revisión). Es MUY probable que la calibración de voz (T22) necesite un
  ajuste tras la primera prueba real, igual que pasó en la web (dos rondas de calibración).
- **Tareas cerradas desde la última limpieza**: 27 en total (16 de la web + 11 de iOS desde la
  última limpieza, que nunca se hizo) — **la pasada anti-deriva está MUY atrasada**, debe ser el
  siguiente foco de trabajo si no hay más features pedidas.

## Qué funciona (verificado por el verificador)

*Smoke-list curada: las funcionalidades núcleo, máx. ~15 filas. El historial completo de
logros vive en las tareas cerradas de TAREAS.md con su evidencia — esas no se borran.*

| Funcionalidad | Verificada | Cómo se probó |
|---|---|---|
| Web app: cámara, grabación, descarga | 2026-07-10 | **CONFIRMADO POR EL USUARIO en iPhone real** (bug de corte ~20s en investigación) |
| Web app: flujo simplificado + voz + diseño (T12/T13) | 2026-07-10 | **CONFIRMADO POR EL USUARIO** |
| Web app: publicación en GitHub Pages | 2026-07-10 | Se actualiza en cada push, confirmado repetidamente |
| iOS nativo: proyecto Xcode completo compila | 2026-07-10 | `xcodebuild` → `BUILD SUCCEEDED`, 0 warnings, re-verificado independientemente en CADA tarea T16-T27 |
| iOS nativo: arranca sin crash en simulador | 2026-07-10 | `simctl install`+`launch`, PID vivo confirmado — NO probado con cámara/mic reales (simulador no tiene) |
| iOS nativo: auditoría App Store Review (T27) | 2026-07-10 | Informe completo en `ios/AppStore/revision-appstore.md`, 6/6 bloques PASA, sin hallazgos de falla |

## Bloqueos y decisiones pendientes

- **Web app**: corte de grabación a los ~20s sin confirmar resuelto (T15b lo mitigó, no está
  probado). T13/T14 tampoco tuvieron confirmación explícita del usuario antes de que llegara
  feedback nuevo.
- **iOS nativo**: TODO el camino feliz con hardware real (cámara, mic, guardar en Fotos, y sobre
  todo la calibración de voz de T22) está sin confirmar — este entorno no tiene cámara/mic físicos
  ni puede correr GUI interactiva de Xcode. Es el paso inmediato que le toca al usuario.
- **Pasada anti-deriva MUY atrasada** (27 tareas cerradas sin hacerla nunca): próxima sesión,
  revisar código muerto, duplicados, y confirmar que MAPA.md (recién actualizado con la sección
  iOS) sigue cuadrando con la realidad tras el uso real del usuario.
- Dos productos en un solo repo (web en raíz + iOS en `ios/`) sin código compartido — intencional,
  documentado en el ADR de ARQUITECTURA.md.

## Última sesión

2026-07-10 — sesión extremadamente larga: instalación del sistema + v1 web completa (T1-T11) +
GitHub Pages + 4 rondas de feedback real en iPhone (T12-T15b) + pivote a app nativa iOS pedido por
el usuario tras problemas de calidad/control de cámara en la web + plan completo (T16-T27) +
ejecución completa de la app nativa en la misma sesión, incluyendo assets de App Store, metadata,
política de privacidad, y auditoría final del "evaluador" (T27) sin hallazgos de falla. Todo
publicado en GitHub. Quedan dos productos listos para que el usuario los pruebe/entregue.
