# Arquitectura

*La escribe y mantiene el arquitecto. Crece por decisiones (ADRs), nunca se reescribe la historia.*

## Stack

| Capa | Tecnología | Por qué |
|---|---|---|
| Frontend | HTML + CSS + JavaScript vanilla, sin build step | El deliverable es "entrar a la carpeta, abrir index.html" y subirlo tal cual a cualquier hosting estático. Un build (Vite/React) añade una etapa de compilación innecesaria para una app de una sola pantalla; vanilla es lo más simple que cumple. |
| Cámara/mic | `getUserMedia` (MediaDevices API) | API nativa del navegador, funciona en Safari iOS 14.3+ sin librerías. |
| Grabación de video | `MediaRecorder` API | Nativo, soportado en Safari iOS moderno (mp4/h264 vía codecs disponibles); graba directo el stream de cámara. |
| Detección de ritmo de habla | Web Audio API (`AnalyserNode` sobre el stream del micrófono) para medir energía/actividad de voz en tiempo real (VAD simple por umbral de volumen), no reconocimiento de texto | No se necesita transcribir lo que dice el usuario, solo saber si está hablando y qué tan rápido/fuerte — eso se puede inferir de la energía del audio sin depender de Web Speech API (que en Safari iOS tiene soporte limitado/inconsistente). |
| Persistencia del guion | `localStorage` | No hay backend ni cuentas (fuera de alcance v1); el guion se guarda en el propio dispositivo. |
| Distribución | PWA (manifest.json + estático) | Permite "agregar a pantalla de inicio" en iOS Safari y correr en pantalla completa sin barra de navegador. |
| Hosting | GitHub Pages, sirviendo `main` desde la raíz | HTTPS automático (requisito duro para `getUserMedia`/`MediaRecorder`/`AudioContext` en Safari iOS), gratis, y coincide exactamente con el requisito "solo subir la carpeta" — sin pipeline de build ni configuración adicional. |

## Estructura

Un solo `index.html` como entrada, con `css/` y `js/` para separar estilos y lógica por módulo
(cámara, teleprompter/scroll, detección de voz, editor de guion, ajustes de estilo). Sin
bundler: los `<script>` se cargan directo como módulos ES (`type="module"`). El detalle
archivo por archivo vive en MAPA.md.

## Decisiones (ADRs)

### 2026-07-10 — Sin backend, sin build step, todo en el cliente

- **Porqué**: el requisito explícito es "entrar a la carpeta, al index, y subirlo al hosting" —
  eso pide un sitio estático simple. No hay necesidad de servidor (no hay cuentas, no hay datos
  compartidos entre dispositivos). Un build step (Vite/webpack) complica el "solo súbelo" sin
  aportar nada que vanilla JS no resuelva para una sola pantalla.
- **Descartado**: React/Vite (overhead de build para una app pequeña de una sola vista);
  backend con Node (no hay necesidad de persistencia server-side ni auth en v1).

### 2026-07-10 — Detección de ritmo de habla por energía de audio (VAD simple), no Web Speech API

- **Porqué**: Web Speech API (reconocimiento de voz a texto) tiene soporte pobre e inconsistente
  en Safari iOS, y el objetivo no es transcribir sino medir actividad/ritmo de voz — eso se
  logra de forma confiable y ligera con Web Audio API (`AnalyserNode`) midiendo volumen/energía
  en el tiempo, sin depender de reconocimiento de lenguaje.
- **Descartado**: Web Speech API (soporte inconsistente en iOS Safari, no resuelve mejor el
  problema real que es "¿está hablando y a qué ritmo?", no "¿qué está diciendo?").

### 2026-07-10 — Repo en GitHub + GitHub Pages como hosting (reemplaza la decisión de "solo local")

- **Porqué**: el usuario pidió explícitamente publicar en GitHub y exponer `index.html` desde
  `main`. GitHub Pages cumple sin costo, con HTTPS automático (crítico: sin HTTPS, Safari iOS
  bloquea `getUserMedia`/`AudioContext` — ya causó un bug de UX confuso al probar por HTTP/túnel),
  y sin cambiar nada del stack (sigue siendo estático, sin build). Repo público en la cuenta
  `juandiegorodri` (`https://github.com/juandiegorodri/teleprompter-app`), sirviendo desde la raíz
  de `main`. URL pública: `https://juandiegorodri.github.io/teleprompter-app/`.
  Autenticación de `gh` vía `gh auth login --web` (no había `gh` ni Homebrew instalados; se
  descargó el binario oficial de la release de GitHub a `~/.local/bin/gh`).
- **Descartado**: Vercel/Netlify (el usuario ya había descartado hosting externo antes; GitHub
  Pages es la opción más directa dado que ya se pedía crear el repo en GitHub); repo privado
  (GitHub Pages gratis no funciona en repos privados en el plan free).

### 2026-07-10 — App nativa iOS (SwiftUI + AVFoundation) en `ios/`, dentro del mismo repo

- **Porqué**: tras varias rondas de bugs de calidad/control de cámara achacables a las
  limitaciones de `getUserMedia`/`MediaRecorder` en Safari (resolución, fps, corte de grabación),
  el usuario pidió pasar a una app nativa de iOS con control real de calidad de cámara, fps y
  lente — eso solo lo da `AVFoundation` (`AVCaptureSession`), no la Web API. El usuario confirmó
  que ya tiene cuenta de Apple Developer y decidió el enfoque nativo completo (no un wrapper
  WKWebView) precisamente para resolver el problema de raíz. Vive en `ios/` dentro del mismo repo
  `teleprompter-app` (decisión del usuario) — un solo lugar para toda la historia del proyecto,
  aunque son dos plataformas con dos stacks independientes sin código compartido.
  - Bundle identifier: `com.juandiegorodri.teleprompter`. Nombre en App Store: **TelepromtCam**.
  - UI: SwiftUI (declarativa, moderna, menos código que UIKit para overlays/paneles de ajustes).
  - Cámara: `AVCaptureSession` con `AVCaptureDevice` — permite elegir resolución/preset, fps
    (`activeVideoMinFrameDuration`/`activeVideoMaxFrameDuration`), y lente (`.builtInWideAngleCamera`
    frontal/trasera) de verdad, a diferencia de los `constraints` "ideales" (no garantizados) de
    `getUserMedia`.
  - Grabación: `AVCaptureMovieFileOutput` (o `AVAssetWriter` si se necesita más control fino),
    sin el bug de corte de `MediaRecorder` en Safari — la captura nativa no depende de que la
    pestaña/pantalla no se atenúe de la misma forma que en un navegador.
  - Detección de voz: `AVAudioEngine` con un `installTap` sobre el nodo de entrada, mismo enfoque
    conceptual de VAD por energía RMS que en la web (mismo ADR de "no Web Speech API" — se
    mantiene: no hace falta transcribir, solo medir energía/ritmo).
  - Persistencia: `UserDefaults` para ajustes simples (equivalente nativo de `localStorage`);
    `FileManager` (carpeta de Documentos de la app) para el guion de texto si crece mucho.
  - Sin backend, sin dependencias de terceros (SPM/CocoaPods) salvo que una tarea puntual lo
    justifique con su propio ADR — mismo espíritu de "lo aburrido y probado" que en la web.
- **Descartado**: WKWebView wrapper de la web app (no resuelve el problema de raíz que motivó el
  cambio — sigue limitado por lo que expone el navegador); Objective-C (SwiftUI/Swift es el
  estándar actual, sin razón para el lenguaje legado); React Native/Flutter (el usuario pidió
  explícitamente nativo con "librerías adecuadas" para máxima calidad — un framework
  multiplataforma reintroduce una capa de abstracción sobre la cámara, justo lo que se quiere
  evitar).
- **Límite importante que el arquitecto debe comunicarle al usuario**: la publicación real en App
  Store (firmar con el Apple Developer Program, subir el build vía Xcode/Transporter, completar
  App Store Connect) es una acción que solo el usuario puede ejecutar con sus propias credenciales
  — el agente deja el proyecto, los assets y los textos listos, pero no ejecuta el submit.

### 2026-07-10 — Sub-decisión: estructura de carpetas iOS + build verificable por línea de comandos (sub-ADR del ADR nativo)

*Sub-decisión técnica no cubierta por el ADR nativo anterior; la escribe el arquitecto porque
condiciona el DoD de todas las tareas de código iOS.*

- **Hallazgo del entorno (verificado 2026-07-10)**: este equipo SÍ tiene `Xcode 26.6`
  (`xcodebuild`, `swift 6.3.3`, `swiftc`), `xcrun simctl` con un simulador `iPhone 17 Pro`
  (iOS 26.5) y `sips` (redimensionado de PNG nativo). NO tiene `xcodegen`, `tuist` ni Python PIL.
  Corrección importante al supuesto inicial: la compilación por línea de comandos **es posible y
  verificable en este entorno** (no es del todo headless para *build*); lo que NO es posible es la
  prueba visual/funcional interactiva (grabar con cámara real, ver overlay sobre video en vivo,
  sentir la calibración de voz con micrófono real) — eso sigue siendo del usuario en su iPhone,
  igual que pasó con Safari iOS en la web app.
- **Decisión — proyecto `.xcodeproj` real y comprometido, con grupo sincronizado con el sistema de
  archivos (file-system synchronized group, Xcode 16+ / `PBXFileSystemSynchronizedRootGroup`)**: el
  scaffold genera y compromete un `ios/TelepromtCam.xcodeproj` real (el usuario solo abre y compila,
  sin instalar herramientas). Para evitar la fragilidad clásica de editar el `project.pbxproj` a mano
  en cada tarea (lo que rompería la regla de "build verde tarea a tarea"), la carpeta de fuentes se
  declara como **grupo sincronizado con el sistema de archivos**: agregar un `.swift` nuevo dentro de
  la carpeta lo incluye automáticamente en el target, sin tocar el pbxproj. Así cada tarea añade
  archivos Swift sin editar la definición del proyecto.
  - **Descartado**: XcodeGen/Tuist (`project.yml`) — no están instalados en este entorno, así que el
    constructor no podría regenerar/verificar el proyecto aquí, y obligarían al usuario a
    `brew install` una herramienta antes de abrir en Xcode; el grupo sincronizado nativo resuelve el
    mismo problema (agregar archivos sin editar pbxproj) sin dependencia externa. Descartado también
    editar el pbxproj a mano por archivo (fragilidad que rompe el build entre tareas).
- **Ancla de verificación (DoD) para toda tarea de código iOS** — lo que SÍ es verificable sin GUI:
  1. `xcodebuild -project ios/TelepromtCam.xcodeproj -scheme TelepromtCam -sdk iphonesimulator
     -destination 'generic/platform=iOS Simulator' build` termina con `** BUILD SUCCEEDED **` y 0
     errores (warnings admisibles, anotados).
  2. `swiftc -parse` (o el propio build) sin errores de sintaxis en los archivos tocados.
  3. Revisión de código exhaustiva contra el alcance.
  4. (Opcional, cuando aporte) smoke-launch headless en el simulador vía `xcrun simctl` para
     confirmar que la app arranca sin crash de inicio.
  - **La prueba visual/funcional final en simulador GUI o dispositivo real la hace el usuario** — se
    declara explícito en cada tarea, mismo patrón que la web app.
- **Estructura de carpetas de `ios/`** (la referencia canónica; MAPA.md debe reflejarla al cierre):
  - `ios/TelepromtCam.xcodeproj/` — proyecto comprometido (grupo sincronizado).
  - `ios/TelepromtCam/` — código fuente (grupo sincronizado). Dentro: `App/` (entry `@main`,
    `Info.plist`, `Assets.xcassets` con AppIcon + AccentColor, `LaunchScreen`), `Camara/`
    (AVCaptureSession, preview, grabación), `Voz/` (AVAudioEngine VAD), `Teleprompter/` (overlay +
    scroll), `Editor/`, `Ajustes/` (modelo + pantalla), `Comun/` (utilidades, PHPhotoLibrary).
  - `ios/AppStore/` — entregables de texto para App Store Connect (metadata, política de privacidad,
    checklist de publicación) en `.md`/`.txt` listos para copiar/pegar; NO forman parte del target.
  - **Bundle id** `com.juandiegorodri.teleprompter`, **display name** `TelepromtCam`, **deployment
    target iOS 17.0** (permite `@Observable`, `TimelineView`, SwiftUI moderno; cubre esencialmente
    todos los dispositivos activos en 2026 — "lo aburrido y probado" sin arrastrar APIs legacy).
