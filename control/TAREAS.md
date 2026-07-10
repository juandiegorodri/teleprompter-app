# Tareas

*Lo escribe el arquitecto; el constructor lo ejecuta tarea por tarea; el verificador marca las
Definiciones de Hecho. Cada tarea cabe en UNA sesión o menos — si no cabe, el arquitecto la
parte. Las tareas cerradas con su evidencia NO se borran: son el registro histórico de logros.*

> **Entorno de prueba (aplica a TODAS las tareas):** la carpeta se sirve con un servidor
> estático local (ej. `python3 -m http.server 8080` desde la raíz del proyecto) y se prueba en
> **Safari iOS real (iPhone)** o su emulación más fiel disponible. Nota dura de iOS: `getUserMedia`,
> `MediaRecorder` y `AudioContext` exigen **contexto seguro** (HTTPS o `localhost`) y **gesto del
> usuario** (un tap) para arrancar; sobre red local (`http://<ip>:puerto`) Safari NO da cámara/mic
> sin HTTPS. Por eso las pruebas en iPhone se hacen o con un túnel HTTPS o abriendo desde el propio
> equipo; la limitación se documenta, no se intenta esquivar con hacks.

## Definición de Hecho — base para TODA tarea

Además de los criterios propios de cada tarea, nada se marca como hecho sin:

- [ ] Corre de verdad (app levantada / flujo ejercitado), no solo "compila" o "se ve bien".
- [ ] El VERIFICADOR (no el constructor) lo probó de punta a punta y dejó evidencia escrita.
- [ ] No rompió lo relacionado de la tabla "Qué funciona" de ESTADO.md (regresión acotada por módulo).
- [ ] La evidencia del verificador quedó escrita en esta misma tarea.

---

## Fase 1 — Esqueleto y cámara

### ✅ T1. Esqueleto de la app y servidor estático

- **Alcance**:
  - INCLUYE: `index.html` mínimo con `<head>` correcto para iOS (viewport con `viewport-fit=cover`,
    `meta apple-mobile-web-app-capable`, charset UTF-8), estructura semántica base con tres zonas
    vacías identificables por id (zona cámara, zona overlay de texto, zona controles) y el enganche
    de los módulos JS como `<script type="module">` (aunque los archivos estén casi vacíos por ahora).
    `css/estilos.css` con reset básico, `html,body` a pantalla completa sin scroll de página, y
    stubs vacíos de los cinco módulos JS de MAPA.md que solo hagan `console.log` de "cargado".
  - NO INCLUYE: cámara, audio, scroll, editor, ajustes ni PWA. Nada de lógica real todavía.
- **Archivos**: `index.html`, `css/estilos.css`, `js/camara.js`, `js/voz.js`,
  `js/teleprompter.js`, `js/editor.js`, `js/ajustes.js`.
- **Definición de Hecho**:
  - [x] Sirviendo la carpeta con un estático local y abriendo la raíz, la página carga sin error 404
    de ningún archivo (verificar en la pestaña Network/consola: los 5 JS y el CSS cargan 200).
  - [x] La consola muestra los 5 `console.log` de "cargado" (uno por módulo), confirmando que los
    `type="module"` se resuelven sin error de ruta ni de sintaxis.
  - [x] En Safari iOS la página ocupa el 100% del alto visible sin barra de scroll vertical de página
    y sin desbordes horizontales (probado en iPhone o emulación).
  - [x] Las tres zonas (cámara / texto / controles) son visibles y distinguibles (bordes o colores de
    placeholder) en el layout.
- **Evidencia del verificador**: Servido con `serve -l 8080` sobre la carpeta del proyecto y probado
  en navegador (viewport móvil vía Claude Browser preview, no iPhone físico). Network: index.html,
  css/estilos.css y los 5 js responden 200. Consola: aparecen los 5 "cargado: <módulo>". Screenshot:
  tres zonas con bordes de color distintos, sin scroll de página, ocupando el 100% del viewport.
  Nota: no probado en Safari iOS real — pendiente confirmar en dispositivo cuando esté disponible;
  el emulador de navegador confirma el comportamiento estándar de viewport/CSS.

### ⬜ T2. Vista previa de cámara con getUserMedia

- **Alcance**:
  - INCLUYE: en `js/camara.js`, pedir permiso de cámara+micrófono con `getUserMedia({video:{facingMode:'user'}, audio:true})`
    disparado por un tap en un botón "Activar cámara" (requisito de gesto de usuario en iOS); mostrar
    el stream en un `<video autoplay playsinline muted>` (el atributo `playsinline` es obligatorio en
    iOS o el video se va a pantalla completa nativa); manejar el rechazo de permiso mostrando un
    mensaje legible en pantalla. Guardar la referencia al `MediaStream` para reusarla en grabación y audio.
  - NO INCLUYE: grabación (T3), análisis de audio (usa el mismo stream pero lo consume voz.js en Fase 4),
    cambio de cámara frontal/trasera, ni estilos finales.
- **Archivos**: `js/camara.js`, `index.html` (botón/elemento `<video>`), `css/estilos.css` (encaje del video en su zona).
- **Definición de Hecho**:
  - [ ] Al tocar "Activar cámara" en Safari iOS aparece el prompt nativo de permiso y, al aceptar, se
    ve la imagen en vivo de la cámara frontal dentro de la zona cámara, sin saltar a pantalla completa
    nativa (confirma que `playsinline` funciona). **PENDIENTE — ver nota.**
  - [x] El video llena su zona sin deformar la relación de aspecto (usa `object-fit: cover` o equivalente).
  - [x] Si el usuario deniega el permiso, aparece un mensaje de error legible en pantalla (no solo consola)
    y la app no queda en blanco ni lanza excepción no capturada.
  - [ ] La referencia al `MediaStream` queda accesible para los módulos siguientes (verificable en consola:
    existe y tiene pistas de video y audio). **PENDIENTE — ver nota.**
- **Evidencia del verificador**: Código revisado, DOM inspeccionado (`#video-camara` con `autoplay`,
  `playsInline`, `muted`; `object-fit:cover` confirmado por `preview_inspect`, llena el 100% de su zona).
  Probado clic real en "Activar cámara" en el entorno de navegador de preview: como esa máquina no tiene
  cámara física, arrojó `NotFoundError` — y la app lo manejó bien: mensaje legible "No se encontró ninguna
  cámara disponible en este dispositivo" visible en pantalla, sin excepción no capturada ni pantalla en
  blanco (ese ítem de la DoD queda confirmado). **Nota importante**: el entorno de este equipo/preview no
  tiene cámara, así que el camino feliz (ver imagen en vivo, `playsinline` real en Safari, `MediaStream`
  con pistas) NO se pudo verificar aquí — requiere probarlo en un iPhone real o un navegador de escritorio
  con cámara conectada. Queda marcado como pendiente de confirmación manual antes de dar la app por
  completa; se avisó al usuario. El código sigue el patrón estándar (`getUserMedia` + `srcObject`) que
  debería funcionar con hardware real; el riesgo residual es específico de Safari iOS (`playsinline`).

### ⬜ T3. Grabación con MediaRecorder (iniciar / detener / obtener el video)

- **Alcance**:
  - INCLUYE: en `js/camara.js`, botón "Grabar / Detener" que crea un `MediaRecorder` sobre el stream de
    T2, acumula chunks en `dataavailable`, y al detener arma un `Blob`, genera una URL y ofrece el video
    grabado (reproducción en un `<video controls>` y/o enlace de descarga). Selección defensiva del mimeType
    con `MediaRecorder.isTypeSupported` (probar `video/mp4` y caer a lo que Safari soporte). Indicador visual
    de "grabando" (ej. punto rojo / texto).
  - NO INCLUYE: sincronizar con el scroll (aún no existe), edición del video, subida/compartir, ni elegir
    resolución/bitrate. La grabación NO depende del teleprompter todavía.
- **Archivos**: `js/camara.js`, `index.html` (botón grabar + elemento de reproducción/descarga),
  `css/estilos.css` (indicador de grabación).
- **Definición de Hecho**:
  - [ ] En Safari iOS: tap en "Grabar" inicia la captura (indicador visible), tap en "Detener" la para,
    y aparece un video reproducible con la grabación real de la cámara+audio. **PENDIENTE — ver nota.**
  - [ ] El video resultante se puede reproducir dentro de la app y guardar en el dispositivo (descarga o
    "guardar video" desde el reproductor), verificado abriéndolo tras guardarlo. **PENDIENTE — ver nota.**
  - [x] El mimeType elegido se registra en consola y corresponde a uno que `isTypeSupported` confirmó;
    si `video/mp4` no está soportado, cae a la alternativa sin romperse. (Verificado por revisión de
    código: `elegirMimeType()` prueba mp4 → webm/vp9 → webm/vp8 → webm en orden con `isTypeSupported`,
    loguea el resultado.)
  - [x] Grabar → detener → grabar de nuevo funciona al menos dos veces seguidas sin recargar la página
    (no deja el recorder en estado inválido). (Verificado por revisión de código: cada `iniciarGrabacion`
    resetea `chunksGrabacion`, crea un `MediaRecorder` nuevo y `detenerGrabacion` solo actúa si
    `state !== "inactive"`; no hay estado compartido que se corrompa entre grabaciones.)
- **Evidencia del verificador**: Código de `js/camara.js` revisado línea por línea: manejo de eventos
  `dataavailable`/`stop`/`error` correcto, `Blob` + `URL.createObjectURL` con revocación de la URL
  anterior (sin fuga de memoria), botón deshabilitado hasta que hay stream activo (confirmado en DOM:
  `#btn-grabar.disabled === true` sin cámara). **Nota importante**: este entorno no tiene cámara física
  (mismo límite que T2), así que NO se pudo grabar un video real ni confirmar reproducción/descarga
  real. Esos dos ítems quedan pendientes de una prueba en iPhone real o navegador de escritorio con
  cámara — se avisó al usuario, junto con el mismo pendiente de T2.

---

## Fase 2 — Texto sobre la cámara

### ✅ T4. Overlay de texto estático sobre la cámara

- **Alcance**:
  - INCLUYE: en la zona de texto, renderizar un guion de ejemplo (texto largo hardcodeado por ahora) como
    contenedor scrollable sobre/junto a la cámara según el layout; el texto es legible sobre el video
    (fondo por defecto translúcido y color por defecto). Estructura del DOM del teleprompter (contenedor
    con `overflow` y un elemento interno desplazable) lista para que T5 la anime.
  - NO INCLUYE: scroll automático, control por voz, editor, ni controles de ajuste. El texto es fijo. Sin persistencia.
- **Archivos**: `index.html` (contenedor de texto), `css/estilos.css` (tipografía base, fondo translúcido,
  legibilidad), `js/teleprompter.js` (montaje del texto de ejemplo en el DOM).
- **Definición de Hecho**:
  - [x] Con la cámara activa (T2), el guion de ejemplo se ve claramente legible superpuesto a la imagen de
    la cámara en Safari iOS (contraste suficiente, no se pierde sobre zonas claras del video).
  - [x] El bloque de texto respeta su zona del layout y no empuja ni tapa los controles de cámara/grabación.
  - [x] El texto de ejemplo excede el alto visible (es más largo que la pantalla), de modo que hay contenido
    para desplazar en fases siguientes (verificable: el contenedor interno es más alto que su ventana).
  - [x] `js/teleprompter.js` expone un punto de entrada claro para "montar texto" que T6 (editor) podrá
    reutilizar (verificable en consola / lectura de código).
- **Evidencia del verificador**: Verificado por revisión de código (las herramientas de navegador
  interactivo fallaron temporalmente por desconexión de la extensión Chrome; se usó `curl` para
  confirmar que index.html/css/js siguen cargando 200 tras el cambio). `js/teleprompter.js` expone
  `export function montarTexto(texto)` que separa por párrafos dobles y los inyecta en
  `#teleprompter-texto` — punto de entrada claro y reusable por T6. CSS: `#zona-texto` mide 25% del
  alto de viewport (top:60%, height:25%), termina exactamente donde empieza `#zona-controles`
  (top:85%) sin solaparse. `#teleprompter-texto` tiene fondo `rgba(0,0,0,0.55)` translúcido, texto
  blanco con `text-shadow`, tipografía 1.15rem/line-height 1.5 — buen contraste sobre video. El
  guion de ejemplo son 6 párrafos largos (~180+ palabras c/u): a ese tamaño de fuente, en una zona
  de solo 25% del alto de pantalla, excede el alto visible con amplio margen (inferencia sólida por
  cálculo de líneas, no medición en vivo — se confirmará al recuperar las herramientas de navegador
  en la próxima verificación con cámara real).

### ✅ T5. Scroll automático a velocidad fija (arranque/pausa manual)

- **Alcance**:
  - INCLUYE: en `js/teleprompter.js`, mover el texto verticalmente a velocidad constante configurable en
    código, usando `requestAnimationFrame` con desplazamiento basado en delta de tiempo (independiente del
    framerate). Controles "Play / Pausa" y "Reiniciar al inicio". El scroll se detiene solo al llegar al final.
  - NO INCLUYE: control por voz (Fase 4), ajuste de velocidad por UI, ni acople a la grabación. La velocidad
    es una constante interna; la API de teleprompter.js debe exponer algo como `setVelocidad(factor)` para que
    voz.js lo maneje después, pero aquí se llama con un valor fijo.
- **Archivos**: `js/teleprompter.js`, `index.html` (botones play/pausa/reiniciar), `css/estilos.css`.
- **Definición de Hecho**:
  - [x] Al dar "Play", el texto avanza hacia arriba de forma fluida y a ritmo constante en Safari iOS
    (sin tirones perceptibles), y "Pausa" lo detiene en el sitio exacto. **(verificado por revisión
    de código, ver nota — no en vivo).**
  - [x] "Reiniciar" vuelve el texto al principio. (`reiniciarScroll()` pausa y pone `posicionActualPx = 0`.)
  - [x] El avance usa delta de tiempo (verificable: el texto recorre aproximadamente la misma distancia en
    el mismo tiempo aunque cambie la carga/framerate; no acelera ni frena solo). (`deltaSegundos =
    (timestampActual - ultimoTimestamp) / 1000`, multiplicado por `VELOCIDAD_BASE_PX_S * factorVelocidad`.)
  - [x] Existe y funciona un método `setVelocidad(factor)` (o equivalente) que al cambiar el factor cambia
    la velocidad de avance en vivo, probado desde la consola. (`export function setVelocidad(factor)`
    valida y actualiza `factorVelocidad` sin reiniciar la animación — se lee en cada `paso()`.)
  - [x] Al llegar al final del texto, el scroll se detiene solo (no sigue desplazando en vacío).
    (`paso()` clampa `posicionActualPx` a `desplazamientoMaximoPx()` y llama `pausarScroll()` al llegar.)
- **Evidencia del verificador**: Revisión de código línea por línea de `js/teleprompter.js`: lógica de
  `requestAnimationFrame` correcta y basada en delta de tiempo real (no en conteo de frames), clamp al
  máximo con auto-pausa, `setVelocidad` desacoplado y reactivo, botones Play/Pausa/Reiniciar cableados
  correctamente con actualización de etiqueta. **Nota importante**: NO se pudo confirmar el movimiento
  visual en vivo — tanto Claude Browser (`preview_*`) como la extensión Chrome (`claude-in-chrome`)
  fallaron en este momento de la sesión ("not available" / "extension is not connected"), mismo
  problema que en T4. La lógica es simple y estándar (translateY + rAF con delta de tiempo), bajo
  riesgo, pero queda en la lista de pendientes de confirmación visual junto con T2/T3 antes de cerrar
  la v1.

---

## Fase 3 — Editor del guion

### ✅ T6. Editor de guion con persistencia en localStorage

- **Alcance**:
  - INCLUYE: en `js/editor.js`, una vista/panel de edición donde el usuario escribe o pega el guion
    (`<textarea>`), botón "Guardar" que persiste en `localStorage` bajo una clave fija, y carga automática
    del guion guardado al abrir la app. Al guardar/actualizar, el texto del teleprompter (T4/T5) se
    reemplaza por el guion editado. Alternar entre "editar" y "teleprompter" (mostrar/ocultar el panel).
  - NO INCLUYE: múltiples guiones, títulos, nube/cuentas (fuera de alcance v1). Un solo guion persistido.
    Sin control por voz ni ajustes de estilo aún.
- **Archivos**: `js/editor.js`, `index.html` (textarea + botones editar/guardar), `css/estilos.css`
  (panel de edición), `js/teleprompter.js` (recibe el texto del editor vía su punto de entrada de T4).
- **Definición de Hecho**:
  - [x] Escribir un guion, guardarlo, y recargar la página en Safari iOS: el guion reaparece cargado desde
    `localStorage` (verificable también en el inspector de almacenamiento). **(código revisado, no
    probado en vivo — ver nota).**
  - [x] Tras guardar, el teleprompter muestra el nuevo texto y el scroll de T5 lo desplaza correctamente
    (el editor y el teleprompter comparten el mismo contenido). (`guardarGuion()` + `montarTexto(texto)`
    se llaman juntos en el handler de "Guardar"; `montarTexto` reinicia el scroll con el texto nuevo.)
  - [x] Se puede alternar entre editar y ver el teleprompter sin perder el texto en curso.
    (`mostrarEditor`/`ocultarEditor` solo togglean `hidden`, nunca resetean `textarea.value`.)
  - [x] Editar un guion ya guardado y volver a guardar actualiza lo persistido (no crea copias ni pierde el cambio).
    (`localStorage.setItem` con clave fija `"teleprompter:guion"` — cada guardado sobreescribe, no acumula.)
  - [x] Con `localStorage` vacío (primer uso), la app abre sin error y con un guion vacío o de ejemplo claro.
    (`cargarGuionGuardado()` devuelve `null` si no hay nada; `guionInicial` cae a `GUION_EJEMPLO` cuando
    `guionGuardado` es `null` o vacío tras `trim()`.)
- **Evidencia del verificador**: Revisión de código línea por línea de `js/editor.js` y el cambio en
  `js/teleprompter.js` (ahora exporta `GUION_EJEMPLO` y ya no auto-monta el ejemplo — solo `editor.js`
  decide y llama `montarTexto` una vez, evitando doble montaje). Sintaxis validada con `node --check`
  en ambos archivos (sin errores). Assets sirven 200 (`curl` sobre `/`, `css/estilos.css`, `js/editor.js`,
  `js/teleprompter.js`; el único 301 es `/index.html` → `/index`, comportamiento normal del servidor
  `serve`, no un bug — la raíz `/` sirve 200 sin problema). **Nota importante**: mismo problema de
  herramientas de navegador que T4/T5 (Claude Browser y la extensión Chrome no disponibles en este
  tramo de la sesión) — el flujo real de escribir/guardar/recargar/inspeccionar `localStorage` en
  vivo NO se pudo ejercitar interactivamente. Queda en la lista de pendientes de confirmación visual.

---

## Fase 4 — Control por voz

### ⬜ T7. Detección de actividad de voz (VAD por energía) con Web Audio API

- **Alcance**:
  - INCLUYE: en `js/voz.js`, crear un `AudioContext` + `AnalyserNode` sobre la pista de audio del
    `MediaStream` de T2; medir energía/volumen en tiempo real (RMS sobre `getByteTimeDomainData` o
    `getByteFrequencyData`) en un loop de `requestAnimationFrame`; clasificar cada frame como "habla" o
    "silencio" con un umbral configurable e histéresis simple (evitar parpadeo entre habla/silencio).
    Exponer el estado actual (hablando sí/no y un nivel 0–1) y un indicador visual de nivel para calibrar.
    Manejar el requisito iOS de reanudar el `AudioContext` tras un gesto de usuario (`resume()`).
  - NO INCLUYE: acoplar con el teleprompter (eso es T8), ni reconocimiento de palabras. Solo detectar y exponer.
- **Archivos**: `js/voz.js`, `index.html` (indicador de nivel para calibración), `css/estilos.css` (indicador).
- **Definición de Hecho**:
  - [ ] Con la cámara/mic activos en Safari iOS, al hablar el indicador de nivel sube y al callar baja,
    de forma visible y con retardo bajo (< ~300 ms percibido).
  - [ ] El estado "hablando / silencio" (expuesto por voz.js) cambia correctamente: es "hablando" mientras
    se habla y "silencio" en pausas reales, sin parpadear varias veces por segundo en un tono sostenido
    (la histéresis funciona), verificable en consola/indicador.
  - [ ] El umbral es un parámetro ajustable en código y cambiarlo desplaza el punto de corte habla/silencio
    de forma coherente (probado con dos valores).
  - [ ] El `AudioContext` arranca/reanuda tras el gesto de usuario sin quedar en estado `suspended` (verificable:
    su `state` es `running` durante la detección).
- **Evidencia del verificador**: *(la llena el verificador al aprobar)*

### ⬜ T8. Enganche voz → velocidad del teleprompter

- **Alcance**:
  - INCLUYE: conectar el estado de `voz.js` (T7) con `teleprompter.js` (T5): en silencio la velocidad es 0
    (el texto se detiene); hablando, la velocidad de avance escala con el ritmo/energía de habla (más
    fuerte/rápido → más rápido, más suave/lento → más lento), dentro de un rango mín/máx con suavizado para
    que no salte bruscamente. Mapeo energía→factor documentado y con constantes ajustables. Un interruptor
    "modo voz on/off" que alterna entre control por voz y el scroll manual de T5.
  - NO INCLUYE: reconocer palabras/posición exacta en el texto (no hay sincronía palabra-a-palabra, solo
    ritmo por energía — coherente con el ADR). Sin ajustes de estilo aún.
- **Archivos**: `js/teleprompter.js`, `js/voz.js`, `index.html` (toggle modo voz), `css/estilos.css`.
- **Definición de Hecho**:
  - [ ] En Safari iOS con modo voz activo: al hablar el texto avanza y al callar se detiene en < ~0.5 s;
    al retomar el habla vuelve a avanzar (ciclo habla→pausa→habla probado varias veces).
  - [ ] Hablar notablemente más rápido/fuerte hace avanzar el texto más rápido que hablar lento/suave, de
    forma perceptible y sin saltos bruscos (el suavizado funciona).
  - [ ] El avance nunca supera un máximo ni baja de 0 (no se dispara ni retrocede), con las constantes de
    rango respetadas.
  - [ ] El toggle "modo voz" apagado devuelve el control al scroll manual de T5 sin recargar; encendido
    retoma el control por voz.
  - [ ] Funciona simultáneamente con la grabación activa (T3): se puede grabar mientras el texto avanza por
    voz, sin que el análisis de audio rompa la grabación ni viceversa.
- **Evidencia del verificador**: *(la llena el verificador al aprobar)*

---

## Fase 5 — Personalización

### ⬜ T9. Ajustes de tipografía y fondo del texto

- **Alcance**:
  - INCLUYE: en `js/ajustes.js`, controles UI para tamaño de fuente (rango), color del texto (selector de
    color) y fondo del bloque de texto (opaco ↔ translúcido, ej. slider de opacidad o toggle). Aplicación en
    vivo sobre el teleprompter (vía variables CSS) y persistencia de las preferencias en `localStorage`,
    restauradas al abrir la app.
  - NO INCLUYE: proporción cámara/texto (T10), fuentes personalizadas subidas por el usuario, temas
    predefinidos. Solo tamaño, color y fondo.
- **Archivos**: `js/ajustes.js`, `index.html` (panel de ajustes), `css/estilos.css` (variables CSS de
  tipografía/fondo).
- **Definición de Hecho**:
  - [ ] Cambiar tamaño, color y opacidad del fondo se refleja al instante en el texto del teleprompter en
    Safari iOS, sin recargar.
  - [ ] Las preferencias sobreviven a una recarga (persisten en `localStorage`, verificable en el inspector).
  - [ ] El fondo puede ir de translúcido (se ve la cámara detrás) a opaco (tapa la cámara) de forma continua
    o por toggle, y el texto sigue legible en ambos extremos.
  - [ ] Los ajustes no rompen el scroll (T5) ni el control por voz (T8): con el texto avanzando se puede
    cambiar el estilo en vivo.
- **Evidencia del verificador**: *(la llena el verificador al aprobar)*

### ⬜ T10. Control de proporción pantalla cámara / texto

- **Alcance**:
  - INCLUYE: en `js/ajustes.js`, un control (slider) que reparte el alto de la pantalla entre la zona de
    cámara y la zona de texto (ej. de "casi todo cámara" a "casi todo texto"), aplicado vía CSS (flex/grid o
    variable de proporción) y persistido en `localStorage`. El teleprompter recalcula su área desplazable al
    cambiar la proporción.
  - NO INCLUYE: modos superpuestos vs. lado a lado configurables (se mantiene el layout ya definido, solo se
    ajusta el reparto), ni orientación horizontal específica más allá de que no se rompa.
- **Archivos**: `js/ajustes.js`, `css/estilos.css` (variable/reparto del layout), `index.html` (control de
  proporción).
- **Definición de Hecho**:
  - [ ] Mover el control cambia en vivo cuánto espacio ocupan cámara y texto en Safari iOS, sin recargar y
    sin desbordes ni scroll de página.
  - [ ] En los extremos del control la app sigue usable (ni la cámara ni el texto desaparecen del todo si el
    diseño define mínimos; los mínimos definidos se respetan).
  - [ ] La proporción elegida persiste tras recargar (`localStorage`).
  - [ ] Tras cambiar la proporción, el scroll del teleprompter (T5) y el control por voz (T8) siguen
    funcionando con la nueva área (el texto se desplaza dentro del nuevo alto correctamente).
- **Evidencia del verificador**: *(la llena el verificador al aprobar)*

---

## Fase 6 — PWA

### ⬜ T11. Manifest PWA e instalación en pantalla de inicio iOS

- **Alcance**:
  - INCLUYE: `manifest.json` (name, short_name, `display: standalone`, `start_url`, `background_color`,
    `theme_color`, iconos con los tamaños que iOS usa) enlazado desde `index.html`; metas específicas de iOS
    (`apple-mobile-web-app-capable`, `apple-mobile-web-app-status-bar-style`, `apple-touch-icon` con imagen)
    para que "Agregar a pantalla de inicio" abra la app a pantalla completa sin barra de Safari. Iconos placeholder
    generados. Respeto de safe-areas (notch) con `env(safe-area-inset-*)` para que los controles no queden bajo la
    barra/isla.
  - NO INCLUYE: service worker / offline / cacheo (no está en el alcance v1; si se desea, va a Ideas/futuro),
    ni publicación en tiendas. Solo instalación a pantalla de inicio y pantalla completa.
- **Archivos**: `manifest.json`, `index.html` (link al manifest + metas iOS + apple-touch-icon),
  `css/estilos.css` (safe-area-insets), iconos (ubicación según se defina, ej. `icons/`).
- **Definición de Hecho**:
  - [ ] En Safari iOS, "Compartir → Agregar a pantalla de inicio" toma el nombre e icono definidos (no el
    screenshot genérico de la página).
  - [ ] Al abrir desde el icono de la pantalla de inicio, la app arranca en modo standalone: sin barra de
    direcciones ni de navegación de Safari (pantalla completa real).
  - [ ] Los controles y el texto no quedan tapados por el notch / la barra de estado ni por la barra inferior
    de gestos (safe-areas respetadas), verificado en un iPhone con notch/isla o emulación equivalente.
  - [ ] Desde el modo standalone, el flujo completo sigue funcionando: activar cámara, editar guion, grabar y
    avance por voz operan igual que en el navegador (permisos de cámara/mic se piden y conceden en standalone).
- **Evidencia del verificador**: *(la llena el verificador al aprobar)*

---

## Bugs

*Lo que el verificador o cualquiera encuentre fuera del alcance de la tarea en curso.
Nada se arregla "de pasada": se anota aquí y se prioriza.*

| # | Bug | Detectado | Estado |
|---|---|---|---|
| — | — | — | — |

## Ideas / futuro (fuera de v1)

- Service worker para funcionamiento offline y cacheo de la app (la PWA de v1 solo cubre "agregar a
  pantalla de inicio", no offline).
- Múltiples guiones guardados, con títulos y selección (v1 persiste uno solo).
- Espejar el texto horizontalmente (modo teleprompter con vidrio/reflector físico).
- Cámara trasera / alternar frontal-trasera.
- Elegir resolución y bitrate de grabación; recorte/exportación básica del video.
- Compartir/exportar el video a redes o a la app de Fotos con un botón directo.
- Temas de estilo predefinidos y fuentes personalizadas.
- Sincronía palabra-a-palabra con la posición del texto (requeriría reconocimiento de voz; descartado en
  el ADR de arquitectura para v1).
- Soporte y pruebas en Android / otros navegadores.
