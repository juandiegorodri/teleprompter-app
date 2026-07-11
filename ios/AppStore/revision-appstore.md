# Auditoría de App Store Review Guidelines — TelepromtCam

*Informe de la tarea T27 (Fase 20), pedida explícitamente por el usuario ("corre también un
evaluador"). Ejecutada por el rol verificador como auditoría dedicada al final del proyecto, no
como la verificación de cada tarea individual (esas ya están en TAREAS.md, tarea por tarea).
Fecha: 2026-07-10.*

**Alcance de esta auditoría**: revisión preventiva de los motivos de rechazo más comunes en App
Review. No sustituye ni garantiza la decisión de Apple — esa la toma Apple durante la revisión
real, después de que el usuario envíe el build.

---

## 1. Permisos declarados vs. usados (Guideline 5.1.1)

Cruce completo: cada usage string de `Info.plist` ↔ dónde se usa en el código.

| Usage string | Texto declarado | Usado en | Verdicto |
|---|---|---|---|
| `NSCameraUsageDescription` | "TelepromtCam usa la cámara para grabar tu video mientras lees el guion del teleprompter." | `CamaraController.swift` (`AVCaptureDevice.requestAccess(for: .video)`, `AVCaptureDeviceInput` de video) | ✅ PASA — texto específico (no genérico), uso real confirmado |
| `NSMicrophoneUsageDescription` | "TelepromtCam usa el micrófono para grabar el audio de tu video y para ajustar la velocidad del texto según tu voz." | `CamaraController.swift` (audio input de grabación) + `VozController.swift` (`AVAudioEngine` para VAD) | ✅ PASA — describe ambos usos reales (grabación Y control de velocidad), texto específico |
| `NSPhotoLibraryAddUsageDescription` | "TelepromtCam guarda los videos que grabas en tu carrete de Fotos." | `GuardadoFotos.swift` (`PHPhotoLibrary.shared().performChanges` con `.addOnly`) | ✅ PASA — texto específico, uso de solo-escritura coherente con el permiso "Add" (no se pidió el permiso más amplio de lectura, que sería sobre-alcance) |

No se encontró ningún uso de `AVCaptureDevice`, `AVAudioEngine` o `PHPhotoLibrary` sin su usage
string correspondiente (grep confirmó las 3 APIs solo en los archivos esperados). No hay usage
strings declarados sin uso real (los 3 se usan).

**Veredicto del bloque: PASA.**

---

## 2. Completitud / sin placeholders visibles (Guideline 2.1 / 2.3)

- `grep -rln "lorem\|TODO\|FIXME\|placeholder"` sobre todo `ios/TelepromtCam/**/*.swift` → **0
  resultados**. No hay texto de relleno ni marcadores de trabajo pendiente en el código de producción.
- Ícono de App: T25 reemplazó el placeholder vacío de T16 por un ícono real (single-size 1024,
  sin canal alfa, confirmado con `sips -g hasAlpha` → `no`).
- Launch screen: T25 configuró `UILaunchScreen` con `AccentColor` real (ya no es la entrada mínima
  de T16 sin diseño).
- No se encontraron botones sin acción (`Button {}` vacío) ni vistas condicionadas a datos falsos.

**Veredicto del bloque: PASA.**

---

## 3. Estabilidad

- `xcodebuild -project ios/TelepromtCam.xcodeproj -scheme TelepromtCam -sdk iphonesimulator
  -destination 'generic/platform=iOS Simulator' build` → `** BUILD SUCCEEDED **`, 0 errores, 0
  warnings (re-verificado en esta misma auditoría, no solo confiando en el historial de tareas).
- Smoke-launch real en simulador (`iPhone 17 Pro`, iOS 26.5): `simctl install` + `simctl launch` →
  PID 8990 confirmado vivo vía `simctl spawn ... launchctl list` tras el arranque. Sin crash de
  arranque.
- **Puntos clásicos de crash de AVFoundation, confirmados como defendidos por revisión de código**:
  - **fps fuera de rango** (T20): `aplicarFPS()` en `CamaraController.swift` calcula un clamp
    contra `device.activeFormat.videoSupportedFrameRateRanges` ANTES de tocar
    `lockForConfiguration()`/`activeVideoMinFrameDuration` — nunca asigna un valor no soportado.
  - **Permiso denegado** (T17): `solicitarPermisosYActivar()` verifica el estado ANTES de llamar
    `requestAccess` — no reintenta en loop si ya está `.denied`/`.restricted`; expone mensaje legible.
  - **Cámara trasera ausente** (T18): `cambiarLente()` usa `canAddInput` antes de `addInput`, y
    restaura el input anterior si el nuevo falla — nunca deja la sesión sin cámara.
  - **Preset de calidad no soportado** (T20): `aplicarCalidadCamara()` verifica
    `canSetSessionPreset` antes de `beginConfiguration()`.
  - **Permiso de Fotos denegado** (T24): `GuardadoFotos.guardarVideo` modela el resultado como
    enum (`.exito`/`.permisoDenegado`/`.error`), sin forzar unwraps; el modal muestra mensaje
    legible sin cerrar ni crashear.

**Veredicto del bloque: PASA** (con la salvedad honesta de que "sin crash de arranque en
simulador" no es lo mismo que "sin crash en todos los caminos posibles en hardware real" — los
puntos de mayor riesgo real, cámara/mic/permisos, solo se confirman del todo con el uso real del
usuario en un iPhone, que es justamente el paso siguiente de su checklist).

---

## 4. Metadata coherente (Guideline 2.3.x)

- Nombre "TelepromtCam", descripción, keywords y categoría de `metadata.md` (T26) describen
  exactamente lo que la app hace — no hay funcionalidad prometida en el texto que no exista en el
  código (verificado cruzando la descripción contra T17-T24: cámara frontal/trasera ✓, calidad/fps
  configurables ✓, control por voz sin transcripción ✓, editor de guion ✓, tipografía/color/
  opacidad/velocidad configurables ✓, guardar en Fotos ✓).
- Categoría primaria "Fotografía y vídeo" es adecuada (la función central es grabar video).
- URLs de soporte y privacidad apuntan a `https://juandiegorodri.github.io/teleprompter-app/` y su
  subpágina `/privacidad.html` — ambas dentro del mismo repo/Pages ya publicado y funcionando (la
  URL raíz ya respondía 200 desde la web app; `privacidad.html` se agregó en T26 y quedará servida
  en el próximo build de Pages tras el push).

**Veredicto del bloque: PASA.**

---

## 5. Privacidad (Guideline 5.1)

- `politica-privacidad.md` / `privacidad.html` (T26) afirman explícitamente: uso de cámara,
  micrófono y escritura a Fotos; sin analítica; sin backend; sin recolección ni transmisión de
  datos; todo permanece en el dispositivo.
- Coherencia con el comportamiento real: no hay ninguna llamada de red en todo el código Swift
  (`grep -rn "URLSession\|URLRequest"` sobre `ios/TelepromtCam` → sin resultados salvo, si acaso,
  imports de framework no usados — no se encontró ninguna transmisión de datos), consistente con
  "sin backend, sin analítica".
- `resumen-privacidad-apple.md` mapea cada categoría del cuestionario "App Privacy" a "Data Not
  Collected", con el razonamiento correcto sobre por qué el video grabado (que sí es "User
  Content") no cuenta como "recolectado" según la definición de Apple (que es sobre transmisión
  fuera del dispositivo, no sobre uso/almacenamiento local).

**Veredicto del bloque: PASA.**

---

## 6. Funcionalidad mínima / no "solo web" (Guideline 4.2)

- La app es nativa SwiftUI + AVFoundation + AVKit + Photos, sin `WKWebView` en ningún punto del
  código (confirmado por grep: `WKWebView` no aparece en ningún archivo `.swift` del proyecto).
- Tiene funcionalidad de plataforma real y sustancial: captura de cámara con `AVCaptureSession`,
  procesamiento de audio en tiempo real con `AVAudioEngine`, grabación con
  `AVCaptureMovieFileOutput`, integración con el carrete de Fotos vía `PHPhotoLibrary` — nada de
  esto es replicable por un simple wrapper de sitio web.

**Veredicto del bloque: PASA — no es rechazable por 4.2.**

---

## Resumen ejecutivo

| # | Bloque | Veredicto |
|---|---|---|
| 1 | Permisos declarados vs. usados | ✅ PASA |
| 2 | Completitud / sin placeholders | ✅ PASA |
| 3 | Estabilidad | ✅ PASA |
| 4 | Metadata coherente | ✅ PASA |
| 5 | Privacidad | ✅ PASA |
| 6 | Funcionalidad mínima (no "solo web") | ✅ PASA |

**No se encontraron hallazgos de "falla" que bloqueen la revisión por los motivos comunes
auditados.** No hay tareas de corrección pendientes derivadas de esta auditoría.

**Riesgos residuales que esta auditoría NO puede eliminar** (ninguno es un "hallazgo de falla" —
son límites inherentes de no tener hardware real disponible en este entorno de desarrollo, ya
documentados en cada tarea individual):
- La calibración de la detección de voz (T22) es una estimación sin micrófono real; puede
  necesitar un ajuste tras la primera prueba del usuario, igual que pasó en la versión web.
- El camino feliz completo de cámara/grabación/guardado en Fotos solo se confirma con hardware
  real — el simulador no tiene cámara física.
- La apreciación subjetiva del ícono y el tono del texto de marketing quedan a criterio del
  usuario.

**La decisión final de enviar a revisión, y el juicio de Apple durante esa revisión, quedan del
lado del usuario** — esta auditoría es preventiva, no una garantía de aprobación.
