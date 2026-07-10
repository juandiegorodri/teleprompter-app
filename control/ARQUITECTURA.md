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
