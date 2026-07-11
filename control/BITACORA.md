# Bitácora

*Historia del proyecto, append-only: una entrada por sesión, la más reciente ARRIBA, máximo
10 líneas cada una. NO se lee al arrancar sesión (para eso está ESTADO.md) — se consulta solo
para responder "¿por qué se hizo así?" o "¿cuándo pasó X?".*

## 2026-07-10 — app nativa iOS completa (T16-T27): TelepromtCam lista para Xcode/App Store

- **Hecho**: pivote pedido por el usuario tras problemas de calidad de cámara en la web. Plan
  completo (12 fases del arquitecto) ejecutado de punta a punta: proyecto Xcode, cámara nativa
  (calidad/fps/lente configurables), teleprompter superpuesto, voz por AVAudioEngine, editor, flujo
  de grabación con modal Guardar en Fotos/Descartar, ícono+launch screen, metadata de App Store +
  privacidad, y auditoría final (T27) sin hallazgos de falla.
- **Decidido**: SwiftUI + AVFoundation nativo (no WKWebView wrapper), proyecto en `ios/` del mismo
  repo, bundle id `com.juandiegorodri.teleprompter`, nombre "TelepromtCam". Grupo sincronizado con
  el sistema de archivos en el pbxproj (agregar `.swift` no requiere tocarlo). Aplicada
  explícitamente la lección del bug de mapeo nivel→factor de voz que se cometió en la web (T14).
- **Pendiente**: TODO el camino con hardware real (cámara/mic/Fotos, calibración de voz) — el
  usuario debe abrir el proyecto en Xcode y seguir la checklist final de TAREAS.md hasta publicar.

## 2026-07-10 — v1 implementada completa (T1-T11)

- **Hecho**: las 11 tareas del plan implementadas (esqueleto, cámara, grabación, teleprompter con
  scroll, editor, detección de voz + enganche, ajustes de estilo/proporción, PWA/manifest).
- **Decidido**: sin cámara/mic físicos en el entorno de desarrollo, la verificación fue por
  revisión de código exhaustiva en vez de prueba visual en la mayoría de tareas (T2-T11); las
  herramientas de navegador interactivo estuvieron caídas gran parte de la sesión.
- **Pendiente**: pase de verificación completo en iPhone real (o navegador con cámara) antes de
  entregar; pasada anti-deriva (11 tareas cerradas); arreglar bug #1 (modo voz sin detección activa).

## 2026-07-10 — instalación del sistema

- **Hecho**: sistema de proyecto instalado (control/, enjambre, CLAUDE.md) en carpeta nueva
  `teleprompter-app`.
- **Decidido**: sin backend, sin build step (HTML/CSS/JS vanilla); detección de ritmo de voz
  por energía de audio (Web Audio API), no Web Speech API; solo hosting local por ahora.
- **Pendiente**: plan de tareas del arquitecto y primera tarea (T1).
