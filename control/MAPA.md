# Mapa de archivos

*Para saber dónde buscar SIN explorar el repo. Una línea por carpeta o archivo clave.
Lo actualiza el cronista al cierre cada vez que la estructura cambia. Si este mapa no
cuadra con la realidad, toca pasada anti-deriva.*

## Código (planeado — se confirma tarea por tarea)

| Ruta | Qué es / qué contiene | Rol que la toca |
|---|---|---|
| index.html | Entrada única de la app: estructura de la pantalla (cámara + overlay de texto + controles de edición/ajustes) | constructor |
| manifest.json | Manifiesto PWA (icono, nombre, modo standalone) para "agregar a pantalla de inicio" en iOS | constructor |
| css/estilos.css | Estilos generales, layout cámara/texto, controles de ajuste (tipografía, fondo, proporción) | constructor |
| js/camara.js | Acceso a `getUserMedia`, vista previa de cámara, `MediaRecorder` (iniciar/detener grabación) | constructor |
| js/voz.js | Web Audio API: mide actividad/energía del micrófono para detectar habla y su ritmo (VAD simple) | constructor |
| js/teleprompter.js | Lógica de scroll del texto: avanza según el ritmo detectado por voz.js, se detiene en silencio | constructor |
| js/editor.js | Editor del guion (crear/editar texto), guardado en `localStorage` | constructor |
| js/ajustes.js | Controles de tipografía (tamaño/color), fondo del texto (opaco/translúcido), proporción cámara/texto | constructor |

## App nativa iOS (COMPLETA — T16-T27, ver TAREAS.md para el detalle de cada tarea)

*Proyecto Xcode independiente en `ios/`, sin código compartido con la web app — ver ADR en
ARQUITECTURA.md. Bundle id `com.juandiegorodri.teleprompter`, nombre App Store "TelepromtCam".
Build verificado con `xcodebuild ... build` → `** BUILD SUCCEEDED **`.*

| Ruta | Qué es / qué contiene | Rol que la toca |
|---|---|---|
| ios/TelepromtCam.xcodeproj/ | Proyecto Xcode, grupo sincronizado con el sistema de archivos (agregar `.swift` no requiere editar el pbxproj, salvo `App/Info.plist` que está excepcionado — ver ARQUITECTURA.md) | constructor |
| ios/TelepromtCam/App/ | `TelepromtCamApp.swift` (@main), `ContentView.swift` (compone cámara+overlay+controles+modal), `Info.plist` físico (usage strings + UILaunchScreen), `Assets.xcassets` (AppIcon single-size 1024, AccentColor) | constructor |
| ios/TelepromtCam/Camara/ | `CamaraController.swift`: AVCaptureSession, permisos runtime, preview (`PreviewCamara.swift`), cambio de lente, grabación con AVCaptureMovieFileOutput, aplicar calidad/fps validados; `ModalResultado.swift`: modal obligatorio Guardar en Fotos/Descartar | constructor |
| ios/TelepromtCam/Voz/ | `VozController.swift`: AVAudioEngine, VAD por energía RMS con histéresis, remapeo de rango antes de calcular factor (lección de T14 web aplicada), enganche a velocidad del teleprompter | constructor |
| ios/TelepromtCam/Teleprompter/ | `TeleprompterController.swift`: scroll por delta de tiempo real (TimelineView); `OverlayTeleprompter.swift`: overlay de texto sobre la franja superior de la cámara | constructor |
| ios/TelepromtCam/Editor/ | `PantallaEditor.swift` + `GuionStore.swift`: editor de guion con persistencia en UserDefaults | constructor |
| ios/TelepromtCam/Ajustes/ | `AjustesStore.swift` (modelo+persistencia), `CalidadCamara.swift`/`FPS.swift` (enums), `PantallaAjustes.swift` (UI: calidad/fps/lente/tipografía/velocidad), `PreviewAjustes.swift` (preview en vivo aislado) | constructor |
| ios/TelepromtCam/Comun/ | `GuardadoFotos.swift`: wrapper de PHPhotoLibrary (solo escritura) | constructor |
| ios/AppStore/ | `icono-master-1024.png`, `metadata.md`, `politica-privacidad.md`, `resumen-privacidad-apple.md`, `revision-appstore.md` (informe del evaluador T27) | constructor |
| privacidad.html (raíz del repo) | Página de política de privacidad servida vía GitHub Pages, enlazada desde App Store Connect | constructor |

## Control y configuración

| Ruta | Qué es | Cuándo leerla |
|---|---|---|
| CLAUDE.md | Constitución: protocolos y reglas | Siempre (se carga sola) |
| control/ESTADO.md | El hilo del proyecto | Al arrancar CADA sesión |
| control/TAREAS.md | Backlog con Definición de Hecho | Al tomar o cerrar una tarea |
| control/VISION.md | Qué es el proyecto y su alcance | Solo ante dudas de alcance |
| control/ARQUITECTURA.md | Stack y decisiones (ADRs) | Antes de decisiones técnicas |
| control/BITACORA.md | Historia por sesión (append-only) | Solo para "¿por qué se hizo así?" |
| control/APRENDIZAJES.md | Errores + lecciones | Cuando algo falla o antes de tareas similares |
| .claude/agents/ | Los 5 roles del enjambre | No se leen; se delega en ellos |
