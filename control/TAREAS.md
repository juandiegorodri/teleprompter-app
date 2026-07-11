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

### ✅ T7. Detección de actividad de voz (VAD por energía) con Web Audio API

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
  - [x] Con la cámara/mic activos en Safari iOS, al hablar el indicador de nivel sube y al callar baja,
    de forma visible y con retardo bajo (< ~300 ms percibido). **(código revisado, no probado con
    audio real — ver nota).** El loop corre en cada rAF (~16ms), muy por debajo de 300ms.
  - [x] El estado "hablando / silencio" (expuesto por voz.js) cambia correctamente: es "hablando" mientras
    se habla y "silencio" en pausas reales, sin parpadear varias veces por segundo en un tono sostenido
    (la histéresis funciona), verificable en consola/indicador. (Dos umbrales: `UMBRAL_ENTRAR_HABLA=0.06`
    > `UMBRAL_SALIR_HABLA=0.03` — hace falta cruzar el alto para entrar y bajar del bajo para salir,
    evita parpadeo cerca de un solo umbral.)
  - [x] El umbral es un parámetro ajustable en código y cambiarlo desplaza el punto de corte habla/silencio
    de forma coherente (probado con dos valores). (Constantes en cabecera del archivo, usadas directo
    en la comparación — cambiar su valor desplaza el corte sin más cambios de código.)
  - [x] El `AudioContext` arranca/reanuda tras el gesto de usuario sin quedar en estado `suspended` (verificable:
    su `state` es `running` durante la detección). (`await audioContext.resume()` dentro del handler de
    click de `#btn-activar-voz`, que es un gesto de usuario directo — patrón correcto para iOS.)
- **Evidencia del verificador**: Revisión de código línea por línea de `js/voz.js`: cálculo RMS correcto
  sobre `getByteTimeDomainData` (normaliza a [-1,1], RMS de la ventana), histéresis de dos umbrales bien
  aplicada, `AudioContext`/`AnalyserNode`/`MediaStreamAudioSourceNode` con `resume()` en gesto de usuario,
  sin conexión a `destination` (evita eco/feedback), maneja stream ausente o sin pista de audio con
  mensaje legible. Sintaxis validada con `node --check` (sin errores). Assets sirven 200 (`/`,
  `css/estilos.css`, `js/voz.js` vía curl). **Nota importante**: no hay micrófono real en este entorno
  (mismo límite que cámara en T2/T3) — el comportamiento con audio real (subida/bajada del indicador,
  ausencia de parpadeo con voz real, `state === "running"` en runtime) NO se pudo confirmar en vivo.
  Se suma a la lista de pendientes de confirmación en hardware real antes de cerrar la v1. El diseño de
  histéresis con dos umbrales es un patrón estándar y de bajo riesgo, pero los valores concretos
  (0.06/0.03) probablemente necesiten calibrarse con un micrófono real.

### ✅ T8. Enganche voz → velocidad del teleprompter

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
  - [x] En Safari iOS con modo voz activo: al hablar el texto avanza y al callar se detiene en < ~0.5 s;
    al retomar el habla vuelve a avanzar (ciclo habla→pausa→habla probado varias veces). **(código
    revisado, no probado con voz real — ver nota).** El loop corre a ~60fps con suavizado 0.15/paso:
    converge a factor≈0 en pocos frames tras entrar en silencio, muy por debajo de 0.5s.
  - [x] Hablar notablemente más rápido/fuerte hace avanzar el texto más rápido que hablar lento/suave, de
    forma perceptible y sin saltos bruscos (el suavizado funciona). (`factorObjetivo` escala linealmente
    con `nivel` entre 0.5 y 2.5; `factorSuavizado` converge gradualmente vía interpolación exponencial,
    sin saltos discretos.)
  - [x] El avance nunca supera un máximo ni baja de 0 (no se dispara ni retrocede), con las constantes de
    rango respetadas. (`Math.max(0, Math.min(FACTOR_MAXIMO_HABLANDO, factorSuavizado))` recorta el
    resultado final antes de `setVelocidad()`, incluso durante el transitorio.)
  - [x] El toggle "modo voz" apagado devuelve el control al scroll manual de T5 sin recargar; encendido
    retoma el control por voz. (`activarModoVoz`/`desactivarModoVoz` togglean `modoVozActivo` y llaman
    `iniciarScroll()`/`pausarScroll()` respectivamente; Play/Pausa/Reiniciar de T5 no se tocaron.)
  - [x] Funciona simultáneamente con la grabación activa (T3): se puede grabar mientras el texto avanza por
    voz, sin que el análisis de audio rompa la grabación ni viceversa. (Confirmado por revisión: el
    `AnalyserNode` de voz.js solo hace `fuenteAudio.connect(analyser)` — nunca toca `MediaRecorder` ni
    desconecta/consume el stream que usa `camara.js`; ambos consumidores leen el mismo `MediaStream` de
    forma no exclusiva, como permite la Web API.)
- **Evidencia del verificador**: Revisión de código línea por línea de `js/voz.js` (T8 se implementó ahí,
  reusando el loop de detección de T7 en vez de crear un segundo rAF — decisión razonable, bajo
  acoplamiento, teleprompter.js no cambió). Constantes de rango y suavizado documentadas con comentarios.
  Sintaxis validada (`node --check` en voz.js y teleprompter.js, sin errores). Assets sirven 200.
  **Bug menor detectado (no bloqueante, anotado en sección Bugs)**: si se activa "Modo voz" ANTES de
  activar la detección de voz (`#btn-activar-voz`), `iniciarScroll()` arranca pero `aplicarEngancheVelocidad()`
  nunca se llama (vive dentro de `loopDeteccion`, que solo corre tras activar detección) — el scroll
  queda a la última velocidad conocida en vez de a 0. **Nota importante**: no hay micrófono real en este
  entorno — el ciclo habla→pausa→habla, la percepción de aceleración/desaceleración y la grabación
  simultánea con Modo voz en hardware real quedan pendientes de confirmación, igual que T2/T3/T7.

---

## Fase 5 — Personalización

### ✅ T9. Ajustes de tipografía y fondo del texto

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
  - [x] Cambiar tamaño, color y opacidad del fondo se refleja al instante en el texto del teleprompter en
    Safari iOS, sin recargar. **(código revisado, no probado en vivo — ver nota).** Cada `input` llama
    `document.documentElement.style.setProperty()` directo, sin pasar por `montarTexto`/reflow costoso.
  - [x] Las preferencias sobreviven a una recarga (persisten en `localStorage`, verificable en el inspector).
    (`guardarAjustes` en cada cambio bajo la clave fija `"teleprompter:ajustes"`; `inicializarAjustes`
    los aplica antes de que el usuario interactúe.)
  - [x] El fondo puede ir de translúcido (se ve la cámara detrás) a opaco (tapa la cámara) de forma continua
    o por toggle, y el texto sigue legible en ambos extremos. (`input[type=range] 0-1 paso 0.05` sobre
    `--tp-opacidad-fondo`, usado en `rgba(0,0,0,var(--tp-opacidad-fondo))` — continuo de transparente a
    negro opaco; el color del texto es independiente y ajustable, así que la legibilidad en el extremo
    transparente depende de que el usuario elija un color con contraste, lo cual es esperable en un
    control manual de estilo.)
  - [x] Los ajustes no rompen el scroll (T5) ni el control por voz (T8): con el texto avanzando se puede
    cambiar el estilo en vivo. (Las variables CSS solo afectan `font-size`/`color`/`background`; no tocan
    `transform` (usado por el scroll) ni las funciones de `teleprompter.js`/`voz.js` — cambios ortogonales,
    sin interferencia posible por diseño.)
- **Evidencia del verificador**: Revisión de código línea por línea de `js/ajustes.js`: patrón consistente
  con `editor.js` (mismo manejo de panel oculto/mostrado, misma estrategia de localStorage con fallback
  a valores actuales si no hay nada guardado). Variables CSS confirmadas por grep: `--tp-font-size`,
  `--tp-color-texto`, `--tp-opacidad-fondo` definidas en `:root` de `css/estilos.css` y consumidas
  exactamente en `#teleprompter-texto`/`#teleprompter-contenedor`. Normalización de color a hex
  (`colorAHex`) para compatibilidad con `input[type=color]`. Sintaxis validada (`node --check`, sin
  errores). Assets sirven 200 en el servidor de :8080 (confirmado que sirve `teleprompter-app`, no
  otra carpeta — se verificó con `curl` buscando `panel-ajustes` en el HTML servido). **Nota
  importante**: mismo límite que T4-T8 — sin herramientas de navegador interactivo disponibles en este
  tramo de la sesión, no se pudo confirmar visualmente el cambio en vivo ni el guardado real en
  `localStorage` del navegador. Queda en la lista de pendientes de confirmación visual.

### ✅ T10. Control de proporción pantalla cámara / texto

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
  - [x] Mover el control cambia en vivo cuánto espacio ocupan cámara y texto en Safari iOS, sin recargar y
    sin desbordes ni scroll de página. **(código revisado, no probado en vivo — ver nota).** `--tp-proporcion-camara`
    controla `height` de `#zona-camara` y `top`/`height` de `#zona-texto` vía `calc()`, ambos derivados
    del mismo 85% disponible (controles fijos en 15%) — no hay overflow posible por diseño.
  - [x] En los extremos del control la app sigue usable (ni la cámara ni el texto desaparecen del todo si el
    diseño define mínimos; los mínimos definidos se respetan). Rango `[24, 70]` tanto en el `min/max` del
    `<input>` como en `acotarProporcionCamara()` (red de seguridad para valores viejos en localStorage):
    en 24, cámara ≈20.4% de pantalla; en 70, texto ≈12.75% + controles 15% fijo — ninguna zona desaparece.
  - [x] La proporción elegida persiste tras recargar (`localStorage`). (Se agregó `proporcionCamara` al
    mismo objeto JSON de `"teleprompter:ajustes"` de T9 — no se creó una clave nueva, según lo pedido.)
  - [x] Tras cambiar la proporción, el scroll del teleprompter (T5) y el control por voz (T8) siguen
    funcionando con la nueva área (el texto se desplaza dentro del nuevo alto correctamente). Confirmado
    por lectura de `js/teleprompter.js`: `desplazamientoMaximoPx()` usa `contenedor.clientHeight` leído
    en cada frame de `paso()` (rAF), así que un cambio de altura vía CSS se refleja solo en el siguiente
    frame sin tocar teleprompter.js — no hay estado de alto cacheado que quede obsoleto.
- **Evidencia del verificador**: Revisión de código y grep de conexión: `--tp-proporcion-camara` definida
  en `:root` (default 60) y consumida en `#zona-camara`/`#zona-texto` con `calc()` coherente (suman
  exactamente el 85% disponible, controles fijo 15%). `input-proporcion-camara` conectado en HTML/JS,
  con `acotarProporcionCamara()` aplicado en todos los puntos de entrada (default, carga desde
  localStorage con migración de objetos viejos sin la propiedad, y en cada cambio del input) — buena
  defensa contra valores corruptos o fuera de rango. Sintaxis validada (`node --check`, sin errores).
  Servidor de :8080 confirmado sirviendo la carpeta correcta con el HTML actualizado (`curl`).
  **Nota importante**: mismo límite que T4-T9 — sin herramientas de navegador interactivo disponibles,
  no se pudo arrastrar el slider ni confirmar visualmente el reparto en vivo ni el scroll dentro de la
  nueva área. Con esto se cierra la Fase 5 (Personalización) — todos los pendientes de confirmación
  visual/hardware quedan acumulados para un pase final antes de entregar la v1.

---

## Fase 6 — PWA

### ✅ T11. Manifest PWA e instalación en pantalla de inicio iOS

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
    screenshot genérico de la página). **PENDIENTE — requiere iPhone real, ver nota.**
  - [ ] Al abrir desde el icono de la pantalla de inicio, la app arranca en modo standalone: sin barra de
    direcciones ni de navegación de Safari (pantalla completa real). **PENDIENTE — requiere iPhone real.**
  - [x] Los controles y el texto no quedan tapados por el notch / la barra de estado ni por la barra inferior
    de gestos (safe-areas respetadas), verificado en un iPhone con notch/isla o emulación equivalente.
    (Verificado por revisión de código: `env(safe-area-inset-*)` con fallback aplicado en `#zona-camara`
    y `#zona-controles`; el mecanismo es estándar y correcto — la confirmación visual con notch real
    queda pendiente igual que el resto.)
  - [ ] Desde el modo standalone, el flujo completo sigue funcionando: activar cámara, editar guion, grabar y
    avance por voz operan igual que en el navegador (permisos de cámara/mic se piden y conceden en standalone).
    **PENDIENTE — requiere iPhone real.**
- **Evidencia del verificador**: `manifest.json` validado como JSON correcto (`python3 -m json.tool`),
  con `name`/`short_name`/`display:standalone`/`start_url`/colores/iconos 192 y 512 bien formados.
  Iconos verificados como PNG reales y válidos en los tamaños correctos (`file`: 192x192, 512x512,
  180x180) — generados con un script Python puro (stdlib, sin ImageMagick/rsvg-convert disponibles en
  el entorno), decisión razonable dada la falta de herramientas del sistema. `index.html` enlaza
  manifest, apple-touch-icon e icon correctamente (confirmado por lectura directa). CSS de safe-area
  revisado y correcto. **Nota importante — el elemento central de T11 no se pudo verificar**: instalar
  a pantalla de inicio y abrir en modo standalone es, por naturaleza, una prueba que solo se puede
  hacer en un iPhone real tocando "Compartir → Agregar a pantalla de inicio" — ningún entorno de
  desarrollo headless ni navegador de escritorio la reproduce. Los 3 ítems de la DoD que dependen de
  eso quedan explícitamente pendientes; el archivo/código que los debe satisfacer está completo y
  sigue el patrón estándar documentado (Apple Human Interface Guidelines para PWA), pero la
  confirmación final requiere el dispositivo.

---

## Fase 7 — Ajustes de flujo de uso (feedback de prueba real en iPhone)

### ✅ T12. Flujo simplificado: cámara habilita todo, grabar controla el teleprompter, voz por defecto

- **Alcance**:
  - INCLUYE:
    1. **Botón grande y prominente** para la acción principal: al cargar, es "Activar cámara"; una
       vez la cámara está activa, se convierte en el botón grande de "Grabar" / "Detener".
    2. **Todo deshabilitado hasta activar cámara**: `#btn-modo-voz`, `#btn-play-pausa`,
       `#btn-reiniciar`, `#btn-alternar-editor`, `#btn-alternar-ajustes` y `#btn-grabar` arrancan
       `disabled`. Se habilitan recién cuando `getUserMedia` resuelve con éxito.
    3. **Fusionar la activación de voz con la de cámara**: eliminar el botón separado
       `#btn-activar-voz` — al activar la cámara con éxito, en el mismo gesto de click, también se
       inicializa el `AudioContext`/`AnalyserNode` de voz.js (reusar el mismo tap como gesto de
       usuario válido para `audioContext.resume()`). Modo voz queda **activado por defecto**
       (`modoVozActivo = true` desde el inicio, sin que el usuario tenga que tocar nada).
    4. **El teleprompter NO se mueve hasta grabar**: quitar la llamada a `iniciarScroll()` de
       `activarModoVoz()` — activar/desactivar el toggle de "Modo voz" (ahora movido al menú de
       configuración) solo cambia si el scroll, cuando arranque, será controlado por voz o a
       velocidad manual constante; nunca inicia o detiene el scroll por sí mismo.
    5. **Grabar controla el teleprompter**: el botón grande de grabar, al iniciar, llama
       `iniciarScroll()` (si Modo voz ON, el enganche de T8 toma el control de la velocidad; si
       OFF, corre a la velocidad manual constante de T5). Al detener grabación, llama
       `pausarScroll()`.
    6. **Menú de configuración**: agrupar visualmente Modo voz, Play/Pausa manual, Reiniciar, abrir
       editor y abrir ajustes dentro de un panel/menú secundario (puede reusar el patrón de panel
       oculto de T6/T9), separado del botón grande principal.
    7. **Velocidad por defecto más lenta**: bajar `VELOCIDAD_BASE_PX_S` (teleprompter.js) y/o el
       rango `FACTOR_MINIMO_HABLANDO`/`FACTOR_MAXIMO_HABLANDO` (voz.js) para que el avance por voz
       sea perceptiblemente más lento y legible por defecto — el usuario reportó que "la velocidad
       es muy rápida, no alcanza a leer". Documentar los nuevos valores con un comentario.
    8. **Texto lo más cerca posible de la cámara** dentro del layout actual de zonas apiladas
       (sin superponerlas todavía — eso es diseño, va a Ideas/futuro): eliminar cualquier
       separación/gap visual innecesario entre `#zona-camara` y `#zona-texto`.
  - NO INCLUYE: superponer el texto sobre la visual de cámara, selección de cámara/lente
    (frontal/trasera), preview en vivo de tipografía dentro del panel de ajustes, ni un control de
    velocidad por defecto en el panel de ajustes — todo eso lo pidió el propio usuario para una
    fase de diseño posterior; queda anotado en Ideas/futuro, no se toca aquí.
- **Archivos**: `js/camara.js`, `js/voz.js`, `js/teleprompter.js`, `index.html`, `css/estilos.css`.
- **Definición de Hecho**:
  - [x] Al cargar la app (cámara sin activar), todos los controles secundarios están visiblemente
    deshabilitados; solo el botón grande "Activar cámara" es interactivo. (Los 6 controles del
    panel de configuración tienen `disabled` en el HTML: confirmado por grep — 7 apariciones de
    `disabled` en total, incluye `#btn-alternar-config` y los 5 dentro de `#panel-config`.)
  - [x] Al tocar "Activar cámara" y conceder permiso, en el mismo flujo se habilitan todos los
    controles secundarios Y se activa la detección de voz (sin un botón adicional) Y el botón
    grande cambia a "Grabar". (`activarCamara()` en camara.js: tras `getUserMedia` exitoso, oculta
    `#btn-activar-camara`, muestra/habilita `#btn-grabar`, habilita los 6 IDs de
    `IDS_CONTROLES_SECUNDARIOS`, y llama `inicializarAudioContext(stream)` importado de voz.js —
    todo en el mismo handler, mismo gesto de usuario. `#btn-activar-voz` fue eliminado por completo
    del HTML y del JS, confirmado por grep.)
  - [x] El teleprompter no se mueve ni un píxel hasta tocar "Grabar" — activar cámara, activar/
    desactivar Modo voz, o cualquier otra interacción previa no debe iniciar el scroll. (Confirmado
    por lectura de voz.js: `activarModoVoz()`/`desactivarModoVoz()` ya NO llaman
    `iniciarScroll()`/`pausarScroll()` — solo togglean `modoVozActivo`. `inicializarAudioContext()`
    tampoco toca el scroll. La única llamada a `iniciarScroll()` en todo el código está dentro de
    `iniciarGrabacion()` en camara.js.)
  - [x] Tocar "Grabar" inicia la grabación Y el scroll simultáneamente; con Modo voz ON (default),
    el avance sigue el ritmo de la voz; tocar "Detener" para ambos a la vez. (`iniciarGrabacion()`
    llama `mediaRecorder.start()` seguido de `iniciarScroll()`; el evento `stop` del MediaRecorder
    y el handler de `error` llaman `pausarScroll()`. Con `modoVozActivo` en `true` por defecto, el
    loop de detección de voz —que ya corre desde que se inicializó el AudioContext— sigue aplicando
    `aplicarEngancheVelocidad()` en cada frame, así que el scroll recién arrancado queda controlado
    por voz de inmediato.)
  - [x] Con Modo voz ON por defecto, hablar más lento que antes resulta en un avance perceptiblemente
    más lento que el comportamiento previo a este ajuste (velocidad base reducida). `VELOCIDAD_BASE_PX_S`
    bajó de 40 a 24 (40% más lento) en teleprompter.js; el rango de factor por voz en voz.js bajó de
    [0.5, 2.5] a [0.4, 1.8] — combinado, el avance máximo por voz baja de 100px/s a 43.2px/s
    (-57%), y el mínimo de 20px/s a 9.6px/s. Cambio sustancial y en la dirección correcta.
  - [x] Modo voz, Play/Pausa, Reiniciar, editor y ajustes están agrupados en un menú/panel
    secundario, separados visualmente del botón grande de grabar. (`#panel-config` agrupa
    `#btn-modo-voz`, `#btn-play-pausa`, `#btn-reiniciar`, `#btn-alternar-editor`,
    `#btn-alternar-ajustes`; se abre/cierra con `#btn-alternar-config` — separado de
    `#btn-activar-camara`/`#btn-grabar` en `#zona-controles`.)
- **Evidencia del verificador**: Revisión de código línea por línea de los 5 archivos tocados
  (camara.js, voz.js, teleprompter.js, index.html, css/estilos.css). Sintaxis validada
  (`node --check` en los 3 JS, sin errores). `#btn-activar-voz` confirmado eliminado sin residuos
  (solo quedan comentarios que documentan su eliminación). Los 6 controles secundarios confirmados
  `disabled` por defecto vía grep. Assets sirven 200 en el servidor de :8080 (index.html,
  css/estilos.css, camara.js, voz.js, teleprompter.js). Sin gap/margin extra entre `#zona-camara` y
  `#zona-texto` (ya tileaban exactamente vía `calc()` desde T10, se dejó un comentario confirmándolo
  — la cercanía real al lente físico de la cámara sigue pendiente para la fase de diseño). **Nota
  importante**: mismo límite que el resto de tareas de esta sesión — no hay cámara/mic/AudioContext
  reales en este entorno, así que el flujo completo (gesto real, permisos, arranque de grabación +
  scroll simultáneo, sensación real de la nueva velocidad) NO se pudo probar en vivo. El usuario
  debe confirmarlo en su iPhone (mismo link de GitHub Pages) antes de dar T12 por cerrada del todo.

---

## Fase 8 — Rediseño (texto sobre cámara, preview en vivo, velocidad y lente configurables)

*Pedida por el usuario tras dos rondas de prueba real en iPhone. Cubre lo que en T12 se dejó
anotado en Ideas/futuro como "fase de diseño posterior" — el usuario confirmó que la quiere ya.*

### ✅ T13. Texto superpuesto arriba de la cámara + panel de ajustes con preview en vivo + velocidad y lente configurables

- **Alcance**:
  - INCLUYE:
    1. **Texto superpuesto en la parte superior de la cámara**: en vez del layout actual de zonas
       apiladas (`#zona-camara` arriba, `#zona-texto` debajo), el bloque de texto del teleprompter
       pasa a superponerse sobre la franja superior de `#zona-camara` (donde está el lente frontal
       del iPhone), con `position: absolute`/`z-index` sobre el `<video>`. Debe seguir siendo
       legible (usa el fondo translúcido/opaco y color ya configurables de T9) y no debe tapar
       controles. `#zona-camara` pasa a ocupar prácticamente toda la pantalla disponible (menos
       controles); el control de "proporción cámara/texto" de T10 pasa a significar, en este nuevo
       layout, qué tan alto es el bloque de texto superpuesto (no un reparto de dos zonas separadas
       — ajusta `js/ajustes.js` y su lectura de `--tp-proporcion-camara` para la nueva semántica,
       documentando el cambio).
    2. **Preview en vivo en el panel de ajustes**: agrega un contenedor de demostración (texto de
       muestra corto) dentro de `#panel-ajustes` que se actualiza en tiempo real — tamaño de
       fuente, color, opacidad de fondo Y velocidad de scroll — mientras el usuario mueve cada
       slider, para que vea el efecto ANTES de cerrar el panel y sin necesitar grabar. El preview de
       velocidad debe animarse (el texto de muestra se mueve a la velocidad configurada) para poder
       calibrar qué tan rápido es legible.
    3. **Velocidad configurable en ajustes**: agrega un `<input type="range">` de "Velocidad del
       teleprompter" en `#panel-ajustes`. Expón desde `js/teleprompter.js` una función tipo
       `setVelocidadBase(pxPorSegundo)` que reemplace la constante fija `VELOCIDAD_BASE_PX_S`
       por un valor variable en tiempo real; `js/ajustes.js` la llama al mover el slider y persiste
       el valor en el mismo objeto de `localStorage` de T9/T10 (agrega la propiedad, ej.
       `velocidadBase`). Rango sugerido: 12–45 px/s (el valor actual, 24, como default). Esto debe
       seguir combinándose con el factor de voz de T8 (velocidad efectiva = velocidad base ×
       factor de voz), no reemplazarlo.
    4. **Selector de cámara/lente**: agrega un control (ej. `<select>` o botón toggle) en
       `#panel-ajustes` para elegir frontal/trasera (`facingMode: "user"` vs `"environment"`).
       Al cambiar, debe volver a pedir `getUserMedia` con el nuevo `facingMode` y reemplazar el
       stream activo (parar las pistas del stream anterior con `.stop()` antes de pedir el nuevo,
       para no dejar la cámara vieja encendida). Si el dispositivo no tiene cámara trasera o el
       cambio falla, mostrar un mensaje legible y mantener la cámara anterior activa. Debe
       persistir la preferencia en `localStorage` (mismo objeto de ajustes) y aplicarla la próxima
       vez que se active la cámara.
  - NO INCLUYE: elegir resolución/bitrate de grabación, múltiples perfiles de ajustes guardados,
    ni rediseño visual más allá de lo descrito (paleta, iconografía, etc. quedan fuera).
- **Archivos**: `index.html`, `css/estilos.css`, `js/teleprompter.js`, `js/ajustes.js`,
  `js/camara.js`.
- **Definición de Hecho**:
  - [x] El texto del teleprompter se ve superpuesto sobre la parte superior de la imagen de cámara
    (no en una franja separada debajo), legible con el fondo/color configurados, sin tapar los
    botones de `#zona-controles` ni el panel de configuración. (`#zona-texto` con `position:absolute;
    top:0; z-index:5` sobre `#zona-camara` que ahora ocupa `height:85%`; fondo translúcido de T9
    intacto para legibilidad sobre el video.)
  - [x] En el panel de ajustes, mover cada slider (tamaño, color, opacidad, velocidad) actualiza un
    texto de muestra visible dentro del propio panel en tiempo real, incluida una animación de
    scroll a la velocidad configurada — sin tener que cerrar el panel ni grabar para verlo.
    (`#preview-ajustes-contenedor`/`#preview-ajustes-texto` con rAF propio y aislado en ajustes.js
    — `previewPaso`/`previewIniciar`/`previewDetener`/`previewSetVelocidad` — que arranca/para con
    el panel y no toca el estado del teleprompter real.)
  - [x] Cambiar el slider de velocidad cambia la velocidad real del teleprompter la próxima vez que
    se grabe (o inmediatamente si ya está corriendo), y esa velocidad persiste tras recargar.
    (`setVelocidadBase()` exportada de teleprompter.js reemplaza la constante `VELOCIDAD_BASE_PX_S`
    por la variable `velocidadBasePxS`, usada en `paso()`; persistida en el mismo objeto JSON de
    localStorage bajo `velocidadBase`.)
  - [x] La velocidad configurada por el usuario sigue combinándose correctamente con el control por
    voz de T8 (hablar más rápido/lento sigue acelerando/desacelerando proporcionalmente sobre la
    nueva base, no la reemplaza). (`paso()` sigue calculando
    `velocidadBasePxS * factorVelocidad * deltaSegundos` — el factor de voz de T8 multiplica sobre
    la nueva base variable, no la reemplaza.)
  - [x] El selector de cámara permite cambiar entre frontal y trasera, la vista previa cambia al
    lente correcto, no quedan streams de cámara huérfanos encendidos, y la preferencia persiste
    tras recargar. (`cambiarLente()` pide el stream nuevo ANTES de detener el anterior — solo
    detiene las pistas viejas tras confirmar éxito, evitando streams huérfanos; en fallo mantiene
    el stream anterior intacto y muestra mensaje legible; reconecta voz.js al stream nuevo
    reusando el mismo AudioContext.)
  - [x] Ningún cambio de esta tarea rompe el flujo de T12 (cámara habilita todo, grabar controla el
    scroll, voz activa por defecto). (Confirmado por lectura: `activarCamara()`, `iniciarGrabacion()`,
    `IDS_CONTROLES_SECUNDARIOS`, y el toggle de `#panel-config` de T12 quedaron intactos — T13 solo
    agregó `cambiarLente()` y ajustó `facingModeActual` inicial, sin tocar la lógica de habilitación
    ni el acople grabar→scroll.)
- **Evidencia del verificador**: Revisión de código línea por línea de los 5 archivos tocados
  (index.html, css/estilos.css, teleprompter.js, ajustes.js, camara.js). Sintaxis validada
  (`node --check` en los 5 JS, sin errores). Confirmado por grep que no hay import circular
  (camara.js no importa de ajustes.js — ajustes.js lee la preferencia de lente de localStorage
  directamente para evitarlo, documentado en un comentario). `cambiarLente()` bien defendido:
  éxito-antes-de-destruir, mensajes de error legibles, mantiene stream anterior en fallo. El
  preview en vivo está completamente aislado del teleprompter real (su propio rAF, su propia
  posición, se detiene al cerrar el panel) — no puede interferir con una grabación en curso.
  Assets sirven 200 en el servidor de :8080. **Nota importante**: mismo límite de todas las tareas
  de esta sesión — sin cámara/mic reales en este entorno, el flujo completo (legibilidad real del
  texto superpuesto sobre el video, sensación del preview en vivo, cambio de lente en un iPhone
  real, combinación velocidad-base + voz) NO se pudo confirmar visualmente. El usuario debe
  probarlo en su dispositivo antes de considerar T13 cerrada del todo.

---

## Fase 9 — Calibración de voz, modal de resultado, indicador de grabación (feedback de tercera prueba real)

### ✅ T14. Recalibrar velocidad por voz, modal obligatorio de video grabado, indicador de grabación visible

- **Alcance**:
  - INCLUYE:
    1. **Recalibrar la detección de voz → velocidad**: el usuario reportó que el avance "está muy
       lento y no sigue la velocidad al hablar" — síntoma consistente con que los umbrales de
       histéresis (`UMBRAL_ENTRAR_HABLA=0.06`/`UMBRAL_SALIR_HABLA=0.03` en voz.js) están calibrados
       más altos de lo que un micrófono típico de iPhone produce en RMS normal, así que el estado
       casi nunca pasa a "hablando" y el factor de velocidad queda pegado cerca de 0 sin importar
       cómo hable el usuario. Bajar significativamente ambos umbrales (ej. a un orden de magnitud
       menor, o agregar una ganancia/amplificación al nivel RMS calculado antes de compararlo con
       los umbrales) para que el habla normal cruce el umbral de forma confiable. Subir también el
       piso del rango de factor (`FACTOR_MINIMO_HABLANDO`) y/o la velocidad base por defecto para
       que el avance al hablar sea claramente perceptible (no solo "un poco más que silencio").
       Documentar los nuevos valores con un comentario explicando el razonamiento (esta sigue
       siendo una calibración a ciegas sin micrófono real disponible para probar — dejar claro que
       puede necesitar un ajuste más tras esta ronda).
    2. **Modal obligatorio para el video grabado**: al detener la grabación, el video ya NO aparece
       en una franja fija en la parte inferior sin forma de cerrarla. En su lugar, se abre un modal
       a pantalla completa (overlay oscuro sobre toda la app) que:
       - Muestra el `<video controls>` con la grabación.
       - Tiene exactamente dos botones debajo del video: **"Descargar"** (dispara la descarga real
         del archivo, igual que el enlace de descarga actual) y **"Descartar y grabar de nuevo"**
         (limpia el resultado, no descarga nada).
       - El modal NO se puede cerrar de ninguna otra forma (sin click en backdrop, sin botón X,
         sin tecla Escape) — el usuario está obligado a elegir una de las dos opciones, así nunca
         cierra por accidente sin haber guardado lo que grabó.
       - Cualquiera de las dos opciones cierra el modal y deja la app lista para grabar de nuevo
         (cámara sigue activa, botón "Grabar" disponible, sin necesidad de recargar la página).
       - "Descargar" puede cerrar el modal inmediatamente después de disparar la descarga, o dejar
         el modal abierto con un mensaje de confirmación y un tercer estado "Cerrar" — decide la
         opción más simple y consistente con "elegir una de las dos para cerrar"; documenta cuál.
    3. **Indicador de "grabando" más visible**: el indicator actual (`#indicador-grabando`) es muy
       tenue sobre el video. Cámbialo a un punto rojo sólido y brillante con la animación de
       parpadeo ya existente, con suficiente contraste (fondo oscuro semitransparente detrás si
       hace falta) para que se note claramente sobre cualquier video de fondo — el patrón visual
       estándar de "grabando" (círculo rojo que titila).
  - NO INCLUYE: cambiar el mecanismo de detección de voz (Web Audio API / RMS, sigue siendo el
    ADR vigente), ni agregar reconocimiento de palabras, ni tocar nada de T13 (superposición,
    preview, selector de lente) salvo lo estrictamente necesario para el modal.
- **Archivos**: `js/voz.js`, `index.html`, `css/estilos.css`, `js/camara.js`.
- **Definición de Hecho**:
  - [x] Los umbrales de voz están notablemente más bajos (o el nivel RMS se amplifica) que antes,
    con el razonamiento documentado en un comentario — el enganche de velocidad debería ahora
    reaccionar a un rango típico de habla en vez de quedar pegado cerca de silencio.
    `UMBRAL_ENTRAR_HABLA` 0.06→0.015, `UMBRAL_SALIR_HABLA` 0.03→0.008 (~10x más bajos),
    `FACTOR_MINIMO_HABLANDO` 0.4→0.7. **Corrección adicional hecha en la verificación** (no estaba
    en el reporte del constructor): la fórmula de `aplicarEngancheVelocidad()` multiplicaba `nivel`
    (RMS crudo, realista en rango ~0.015-0.15) directamente contra `(MAX-MIN)` asumiendo que `nivel`
    ya estaba en [0,1] — con valores tan chicos, casi toda la variación se perdía y el factor
    quedaba pegado cerca de `FACTOR_MINIMO_HABLANDO` sin importar qué tan fuerte/rápido hablara el
    usuario (este es probablemente el motivo real de "no sigue la velocidad al hablar"). Se agregó
    `remapearNivelAFraccion()` que remapea `nivel` desde su rango realista
    (`UMBRAL_ENTRAR_HABLA`..`NIVEL_HABLA_MAX_ESPERADO=0.15`) a una fracción 0-1 ANTES de aplicar la
    fórmula, para que el rango completo de factor (0.7-1.8) sí se recorra con voz real.
  - [x] Al detener una grabación, aparece un modal a pantalla completa con el video y exactamente
    dos botones ("Descargar" y "Descartar y grabar de nuevo"); no hay ninguna otra forma de
    cerrarlo (ni click afuera, ni Escape, ni X). (`#zona-resultado` es `position:fixed`, cubre toda
    la pantalla, `z-index:30`; sin listener de click en el backdrop ni de tecla Escape — confirmado
    por lectura de camara.js, los únicos dos listeners que tocan el modal son los de los botones.)
  - [x] Elegir "Descargar" dispara la descarga del archivo real. (Click programático de
    `enlaceDescarga` que ya trae `href`/`download` listos desde el evento `stop` del MediaRecorder.)
  - [x] Elegir "Descartar y grabar de nuevo" (o "Cerrar" tras descargar, según cómo se implementó
    el punto 2) cierra el modal y dejar la app lista para grabar otra vez sin recargar la página.
    (Ambos botones llaman `ocultarModalResultado()`; "Descargar" cierra inmediato tras el click
    programático — decisión documentada en un comentario, razonable y simple; "Descartar" además
    llama `limpiarResultado()` que revoca la URL del blob y limpia el `<video>`. `grabando=false` ya
    se seteó antes en el mismo handler de `stop`, así que "Grabar" vuelve a estar disponible sin
    recargar.)
  - [x] El indicador de "grabando" es un punto rojo sólido, visible con claridad sobre cualquier
    fondo de video, con la animación de parpadeo. (`#indicador-grabando::before`: 13px, círculo rojo
    `#ff0000` con `box-shadow` de brillo, animación de parpadeo aplicada solo al punto — el texto
    "Grabando" queda legible y estático; fondo `rgba(0,0,0,0.65)` detrás para contraste.)
- **Evidencia del verificador**: Revisión de código línea por línea de los 4 archivos tocados
  (voz.js, index.html, css/estilos.css, camara.js). Encontrado y corregido un bug adicional en la
  fórmula de mapeo nivel→factor (ver arriba) que el constructor no detectó — sin este fix, el punto
  1 de la DoD no se habría cumplido realmente pese a bajar los umbrales. Sintaxis validada
  (`node --check` en voz.js tras la corrección, y en camara.js, sin errores). Ids de HTML/JS del
  modal confirmados 1:1 por grep. Assets sirven 200 en el servidor de :8080. **Nota importante**:
  mismo límite de toda la sesión — sin micrófono real, la calibración de voz sigue siendo una
  estimación (ahora la segunda ronda, más la corrección de mapeo) sin poder confirmarse en vivo; el
  modal y el indicador rojo son cambios de UI/CSS de bajo riesgo y alta confianza incluso sin
  prueba visual. El usuario debe confirmar los 3 puntos en su iPhone, en particular si la voz por
  fin sigue el ritmo real al hablar.

---

## Fase 10 — Cuarta ronda de feedback real: velocidad máxima, grabación que se corta, indicador y calidad de cámara

### ✅ T15a. Fix directo: indicador de "grabando" activo sin estar grabando

- **Qué pasaba**: el usuario reportó que el punto rojo de "Grabando" aparecía titilando con solo
  activar la cámara, sin haber tocado "Grabar".
- **Causa encontrada**: `#indicador-grabando { display: flex; ... }` es un selector de ID (alta
  especificidad CSS) que le ganaba al `[hidden] { display: none }` del user-agent stylesheet
  (baja especificidad) — así que `indicadorGrabando.hidden = true/false` en `js/camara.js` nunca
  ocultaba nada de verdad, el punto quedaba siempre visible y parpadeando desde que cargaba la app.
- **Arreglado directo** (cambio de una línea, sin pasar por el enjambre): se agregó
  `#indicador-grabando[hidden] { display: none; }` en `css/estilos.css`, el mismo patrón que ya
  usan `#panel-config`/`#panel-editor`/`#zona-resultado` en el mismo archivo.
- **Evidencia**: revisión de código confirma el patrón de especificidad y la corrección aplicada;
  no se pudo confirmar visualmente en un iPhone real (mismo límite de toda la sesión).

### ✅ T15b. Velocidad máxima del slider, grabación que se corta a los ~20s, calidad de cámara

- **Alcance**:
  - INCLUYE:
    1. **Ampliar el rango de velocidad**: el usuario pidió poder subir más la velocidad de lo que
       permite hoy el slider (`VELOCIDAD_BASE_MIN=12`/`VELOCIDAD_BASE_MAX=45` en `js/ajustes.js`,
       mismo rango en el `<input>` de `index.html`). Sube el máximo notablemente (ej. a 90-100
       px/s) manteniendo el mínimo y el default (24) igual. Ajusta también el rango del `<input>`
       en HTML para que coincida.
    2. **Grabación que se corta ~20s pero el audio de fondo sigue**: bug grave — el video deja de
       avanzar pero el `MediaRecorder` sigue corriendo (agrega audio) hasta que el usuario detiene
       manualmente. Es un problema conocido de Safari iOS con grabaciones largas sin flush
       periódico de datos, y/o con la pantalla bloqueándose o atenuándose durante la grabación
       (iOS puede pausar la captura de video, no la de audio, cuando la pantalla se apaga).
       Mitigaciones a aplicar en `js/camara.js`:
       - Pasar un `timeslice` a `mediaRecorder.start(1000)` (chunks cada 1000ms) en vez de
         `mediaRecorder.start()` sin argumentos — evita acumular todo en memoria sin volcar hasta
         el final, causa conocida de cortes/corrupción en grabaciones largas en Safari iOS.
       - Usar la Screen Wake Lock API (`navigator.wakeLock.request('screen')`) mientras se está
         grabando, para evitar que la pantalla se atenúe/bloquee durante la grabación (causa
         probable del corte de video). Debe pedirse al iniciar grabación y liberarse
         (`.release()`) al detener. Si la API no existe en el navegador (`'wakeLock' in navigator`
         es `false`), degradar sin romper nada — no es soportada en todas las versiones de Safari
         iOS, documentar la limitación con un comentario.
       - Documentar en un comentario que esto es la mejor mitigación posible sin poder reproducir
         el bug en este entorno (sin cámara real); si persiste, puede requerir investigar límites
         de memoria/duración de MediaRecorder en Safari iOS específicamente.
    3. **Calidad de cámara**: el usuario nota que la imagen se ve peor que la cámara nativa del
       iPhone. En `js/camara.js`, en las llamadas a `getUserMedia` (tanto `activarCamara()` como
       `cambiarLente()`), pide una resolución más alta explícitamente en los constraints de video
       (ej. `width: { ideal: 1920 }, height: { ideal: 1080 }` combinado con el `facingMode` ya
       existente) — por defecto los navegadores suelen pedir una resolución conservadora si no se
       especifica. Aclara en el reporte (para que se lo explique al usuario) que aun así nunca va
       a igualar 100% a la app nativa de Cámara, porque esta última usa el pipeline completo de
       procesamiento computacional de fotografía de iOS (HDR, estabilización, etc.) al que
       `getUserMedia` no tiene acceso — pedir mayor resolución es la mejora real y disponible
       vía web, no hay forma de igualar completamente la app nativa desde el navegador.
  - NO INCLUYE: cambiar el mecanismo de grabación (sigue siendo `MediaRecorder`), ni comprimir/
    post-procesar el video, ni tocar el modal de resultado de T14 salvo si el timeslice requiere
    ajustar cómo se arma el `Blob` final (debería seguir funcionando igual, concatenando todos los
    chunks acumulados).
- **Archivos**: `js/ajustes.js`, `index.html`, `js/camara.js`.
- **Definición de Hecho**:
  - [x] El slider de velocidad en Ajustes permite subir notablemente más que antes (nuevo máximo
    documentado), sin romper el mínimo ni el comportamiento por defecto existente. (`VELOCIDAD_BASE_MAX`
    45→100 en ajustes.js; `max="100"` en el `<input>` de index.html; mínimo 12 y default 24 intactos.)
  - [x] `mediaRecorder.start()` pasa a usar un timeslice (ej. 1000ms) — confirmable leyendo el
    código, ya que no se puede reproducir el bug de corte sin cámara real en este entorno.
    (`mediaRecorder.start(1000)` en `iniciarGrabacion()`.)
  - [x] Se pide Screen Wake Lock al iniciar grabación y se libera al detener, con manejo defensivo
    si la API no existe en el navegador (no debe lanzar excepción no capturada). (`pedirWakeLock()`
    verifica `'wakeLock' in navigator` antes de llamar, con `.catch()` en la promesa — nunca lanza
    sin capturar; `liberarWakeLock()` se llama tanto en el evento `stop` como en `error` del
    MediaRecorder, así que el lock siempre se libera sin importar cómo termine la grabación.)
  - [x] Los constraints de `getUserMedia` (en ambos lugares donde se llama) piden una resolución
    ideal más alta que antes. (`width:{ideal:1920}, height:{ideal:1080}` agregado tanto en
    `activarCamara()` como en `cambiarLente()`.)
- **Evidencia del verificador**: Revisión de código línea por línea de los 3 archivos tocados.
  Sintaxis validada (`node --check` en camara.js y ajustes.js, sin errores). Rango del slider
  confirmado idéntico entre HTML (`min="12" max="100"`) y JS (`VELOCIDAD_BASE_MIN=12`,
  `VELOCIDAD_BASE_MAX=100`) por grep. El manejo del Wake Lock es defensivo en los tres frentes que
  importan: API ausente, promesa rechazada, y liberación garantizada en ambos caminos de salida
  (stop/error) del MediaRecorder. **Nota importante — la más relevante de esta tarea**: el corte de
  grabación a los ~20s es un bug reportado en un iPhone real que este entorno headless (sin cámara)
  no puede reproducir ni confirmar que quedó resuelto. Lo aplicado es una mitigación basada en las
  dos causas más probables y documentadas para ese síntoma específico en Safari iOS (falta de
  flush periódico + pantalla apagándose durante la grabación), no una corrección verificada. El
  usuario debe grabar un video largo (>20s) en su iPhone para confirmar si el problema desapareció;
  si persiste, la causa puede ser otra y requerirá más investigación dirigida.

---

# APP NATIVA iOS (SwiftUI + AVFoundation) — Fases 11 a 20

> **Nota de entorno para TODAS las tareas iOS (Fases 11–20):** rige el sub-ADR
> "2026-07-10 — Estructura de carpetas iOS + build verificable por línea de comandos" de
> ARQUITECTURA.md. Resumen operativo:
> - El proyecto vive en `ios/` dentro de este mismo repo, con un `.xcodeproj` real comprometido y un
>   **grupo sincronizado con el sistema de archivos** (agregar `.swift` NO requiere editar el pbxproj).
> - Bundle id `com.juandiegorodri.teleprompter`, display name `TelepromtCam`, deployment target iOS 17.0.
> - **Este entorno SÍ compila** (Xcode 26.6, `xcodebuild`, `swiftc`, `simctl` con simulador iPhone 17
>   Pro, `sips`). Lo que NO puede es la prueba visual/funcional interactiva con cámara/mic reales.
> - **Ancla de DoD de toda tarea de código iOS** (verificable sin GUI): (a) `xcodebuild ... -sdk
>   iphonesimulator ... build` → `** BUILD SUCCEEDED **`, 0 errores; (b) sin errores de sintaxis Swift;
>   (c) revisión de código exhaustiva; (d) opcional smoke-launch headless con `simctl`.
> - **La prueba visual/funcional final la hace el usuario** en simulador GUI o iPhone real — se
>   declara explícito en cada tarea, mismo patrón que la web app.
> - Las tareas están ordenadas para que **el build quede verde desde T16 en adelante** (nunca varias
>   tareas seguidas con el proyecto roto): cada tarea deja algo que compila.

---

## Fase 11 — Scaffold del proyecto Xcode (build verde desde aquí)

### ✅ T16. Scaffold del proyecto Xcode: estructura, Info.plist, permisos, app mínima que compila

- **Alcance**:
  - INCLUYE:
    1. Crear `ios/TelepromtCam.xcodeproj` (proyecto real comprometido) con **grupo sincronizado con
       el sistema de archivos** apuntando a `ios/TelepromtCam/`, un solo target de app iOS, scheme
       `TelepromtCam` compartido (`.xcodeproj/xcshareddata/xcschemes/TelepromtCam.xcscheme`), bundle
       id `com.juandiegorodri.teleprompter`, display name `TelepromtCam`, deployment target iOS 17.0,
       versión de marketing `1.0` y build `1`.
    2. `ios/TelepromtCam/App/TelepromtCamApp.swift` con `@main` y una `ContentView` placeholder
       mínima (p. ej. un `Text("TelepromtCam")`) — solo para que el proyecto compile y arranque.
    3. `ios/TelepromtCam/App/Info.plist` (o INFOPLIST_KEY en build settings, decide el constructor y
       lo documenta) con los **usage strings de privacidad OBLIGATORIOS** — sin ellos Apple rechaza
       la app y la app crashea al pedir el permiso:
       - `NSCameraUsageDescription`: "TelepromtCam usa la cámara para grabar tu video mientras lees el guion del teleprompter."
       - `NSMicrophoneUsageDescription`: "TelepromtCam usa el micrófono para grabar el audio de tu video y para ajustar la velocidad del texto según tu voz."
       - `NSPhotoLibraryAddUsageDescription`: "TelepromtCam guarda los videos que grabas en tu carrete de Fotos." (se usa en T24; se declara ya para no re-tocar Info.plist más tarde.)
       - Orientaciones soportadas (al menos vertical; decide el constructor si incluye landscape),
         `UILaunchScreen` (referencia al launch screen — el asset real llega en T25, aquí basta la
         entrada mínima que no rompa el build).
    4. `ios/TelepromtCam/App/Assets.xcassets` con `AppIcon` (vacío/placeholder — el set real es T25)
       y `AccentColor`, para que el catálogo exista y compile.
    5. Carpetas vacías con un `.swift` de marcador `enum` vacío o un `.gitkeep` según convenga para
       que el árbol `Camara/ Voz/ Teleprompter/ Editor/ Ajustes/ Comun/` exista desde el inicio
       (opcional; el grupo sincronizado no exige carpetas pobladas).
    6. `.gitignore` para artefactos de Xcode dentro de `ios/` (carpeta `build/`, `DerivedData/`,
       `xcuserdata/`, `*.xcuserstate`).
  - NO INCLUYE: cámara, audio, teleprompter, ajustes, editor, iconos reales, launch screen con
    diseño, metadata. Nada de lógica de producto — solo el esqueleto que compila y arranca.
- **Archivos** (todas rutas bajo `ios/`): `TelepromtCam.xcodeproj/` (project.pbxproj + scheme
  compartido), `TelepromtCam/App/TelepromtCamApp.swift`, `TelepromtCam/App/Info.plist`,
  `TelepromtCam/App/Assets.xcassets/`, `ios/.gitignore`.
- **Definición de Hecho**:
  - [x] `xcodebuild -project ios/TelepromtCam.xcodeproj -scheme TelepromtCam -sdk iphonesimulator
    -destination 'generic/platform=iOS Simulator' build` termina en `** BUILD SUCCEEDED **` con 0
    errores (log adjunto en la evidencia).
  - [x] `Info.plist` contiene las 3 claves de privacidad (`NSCameraUsageDescription`,
    `NSMicrophoneUsageDescription`, `NSPhotoLibraryAddUsageDescription`) con textos legibles en
    español (verificable con `plutil -p` o lectura directa).
  - [x] El bundle id efectivo del build es `com.juandiegorodri.teleprompter` y el display name
    `TelepromtCam` (verificable con `xcodebuild -showBuildSettings | grep -E 'PRODUCT_BUNDLE_IDENTIFIER|PRODUCT_NAME|IPHONEOS_DEPLOYMENT_TARGET'`).
  - [x] Agregar un `.swift` nuevo dentro de `ios/TelepromtCam/` y recompilar lo incluye SIN editar el
    pbxproj (prueba de que el grupo sincronizado funciona — el verificador crea un archivo temporal
    trivial, confirma que compila incluido, y lo borra).
  - [x] (Opcional recomendado) smoke-launch headless: `simctl` bootea el simulador, instala el `.app`
    y lo lanza sin crash de arranque (evidencia: el proceso queda vivo / no hay crash log).
  - [ ] Prueba visual final (abrir en Xcode, correr en simulador GUI): **la hace el usuario**.
- **Evidencia del verificador**: Re-verificado independientemente (no solo confiando en el reporte
  del constructor): corrí `xcodebuild` de nuevo y confirmé `** BUILD SUCCEEDED **`; agregué yo mismo
  un `.swift` temporal (`enum VerifTemp {}`) dentro de `ios/TelepromtCam/Comun/`, recompilé sin tocar
  el pbxproj, compiló bien, lo borré — el grupo sincronizado funciona de verdad, no es solo lo que
  reportó el agente. `plutil -p` sobre el `Info.plist` del `.app` construido confirma las 3 claves de
  privacidad con el texto exacto esperado. El pbxproj usa el formato moderno (`objectVersion=77`,
  `PBXFileSystemSynchronizedRootGroup`) — decisión acertada del constructor, evita fragilidad en
  todas las tareas siguientes que agreguen archivos Swift. Info.plist generado vía
  `GENERATE_INFOPLIST_FILE=YES` + `INFOPLIST_KEY_*` (sin archivo físico) — razonable y documentado.
  Smoke-launch en simulador confirmado por el constructor (proceso vivo tras `simctl launch`).
  **Pendiente explícito**: la prueba visual en Xcode/simulador GUI la debe hacer el usuario — este
  entorno solo puede confirmar que compila y arranca sin crash inmediato, no cómo se ve.

---

## Fase 12 — Cámara nativa (AVCaptureSession)

### ✅ T17. Preview de cámara en vivo con AVCaptureSession + permisos runtime

- **Alcance**:
  - INCLUYE: en `ios/TelepromtCam/Camara/`, una clase `CamaraController` (`@Observable` o
    `ObservableObject`) que configura una `AVCaptureSession` con `AVCaptureDeviceInput` de la cámara
    frontal (`.builtInWideAngleCamera`, `.front`) y del micrófono; un `UIViewRepresentable`
    (`PreviewCamara`) que envuelve una `AVCaptureVideoPreviewLayer` (`videoGravity = .resizeAspectFill`,
    equivalente nativo del `object-fit: cover`) para mostrar el stream en SwiftUI; solicitud de
    permisos en runtime (`AVCaptureDevice.requestAccess(for: .video)` y `.audio`) disparada por un tap
    en un botón "Activar cámara"; manejo legible del permiso denegado (mensaje en pantalla, no crash).
    Arrancar/parar la sesión en un hilo de sesión dedicado (no en el main thread) siguiendo el patrón
    estándar de AVFoundation. Guardar la sesión/inputs accesibles para grabación (T18) y audio (T22).
  - NO INCLUYE: grabación (T18), selección de lente frontal/trasera (T18), análisis de audio (T22),
    overlay de texto (T21). Solo ver la cámara en vivo.
  - **Lección de la web (anotada para el constructor)**: en la web, `getUserMedia` exigía gesto de
    usuario y contexto seguro; el equivalente nativo es que `requestAccess` muestra el prompt del
    sistema una sola vez y luego hay que respetar el estado (`authorized`/`denied`/`restricted`) sin
    volver a forzarlo — si está `denied`, dirigir al usuario a Ajustes, no reintentar en loop.
- **Archivos**: `ios/TelepromtCam/Camara/CamaraController.swift`,
  `ios/TelepromtCam/Camara/PreviewCamara.swift`, `ios/TelepromtCam/App/ContentView.swift`
  (integra el preview y el botón).
- **Definición de Hecho**:
  - [x] `xcodebuild ... build` → `** BUILD SUCCEEDED **`, 0 errores.
  - [x] Revisión de código: la sesión se configura y arranca en un hilo dedicado; el
    `AVCaptureVideoPreviewLayer` usa `.resizeAspectFill`; el permiso denegado produce un mensaje
    legible en pantalla y no una excepción/crash.
  - [x] El controlador expone la `AVCaptureSession` y el `AVCaptureDeviceInput` de audio de forma
    accesible para T18/T22 (verificable por lectura de la interfaz pública del tipo).
  - [ ] Prueba visual (ver imagen en vivo de la cámara frontal, prompt de permiso real):
    **la hace el usuario** en simulador (nota: el simulador de iOS no tiene cámara física — el
    usuario debe probar el camino feliz en iPhone real; el simulador sirve para permisos/UI).
- **Evidencia del verificador**: Re-verificado con `xcodebuild` independiente → `** BUILD SUCCEEDED **`.
  Revisión de `CamaraController.swift` línea por línea: `colaSesion` (DispatchQueue serial dedicada)
  para `startRunning()`/`stopRunning()`/configuración, nunca en main; `PreviewCamara.swift` confirma
  `videoGravity = .resizeAspectFill`; `solicitarPermisosYActivar()` verifica el estado ANTES de
  llamar `requestAccess` — si ya es `.denied`/`.restricted` no reintenta, solo actualiza el mensaje
  (exactamente la lección anotada por el arquitecto, bien aplicada); mensajes de error legibles y
  distintos para cámara/micrófono/lente no disponible, todo vía estado observable sin crashear.
  `session` (let público) y `entradaAudio`/`entradaVideo` (`private(set) var`) quedan expuestos con
  buena semántica para T18/T22. **Nota importante**: el simulador de iOS no tiene cámara física —
  ni el constructor ni esta verificación pudieron confirmar el stream de video real ni el prompt de
  permiso real en pantalla. El usuario debe probar en un iPhone real: activar cámara, confirmar
  el prompt del sistema, ver el preview en vivo, y el camino de denegar permiso (mensaje + botón a
  Ajustes).

### ✅ T18. Selección de lente frontal/trasera + grabación con AVCaptureMovieFileOutput

- **Alcance**:
  - INCLUYE: agregar a `CamaraController` un `AVCaptureMovieFileOutput` a la sesión; métodos
    `iniciarGrabacion()` (graba a un archivo temporal en `FileManager.default.temporaryDirectory`) y
    `detenerGrabacion()`, implementando `AVCaptureFileOutputRecordingDelegate` para recibir la URL del
    archivo final y errores; método `cambiarLente(a posicion:)` que reconfigura el input de video a la
    cámara frontal/trasera (`.front`/`.back`) dentro de un `beginConfiguration/commitConfiguration`,
    sin dejar inputs huérfanos ni parar la sesión entera. Estado observable `estaGrabando`. Manejo
    legible si no hay cámara trasera disponible (mantener la actual, mensaje).
  - NO INCLUYE: el modal de resultado / guardar en Fotos (T24), el indicador visual de grabando
    (T24), acople con el teleprompter/scroll (T24), calidad/fps configurables (T20). Aquí la
    grabación arranca/para y entrega una URL de archivo; la resolución/fps usan el default de la
    sesión por ahora.
  - **Lección de la web (anotada)**: en Safari, `MediaRecorder` se cortaba a los ~20s y hubo que
    mitigar con timeslice + WakeLock; nativo con `AVCaptureMovieFileOutput` NO tiene ese problema
    (la captura nativa no se pausa al atenuarse la pantalla igual que el navegador) — no hace falta
    replicar esos hacks. `UIApplication.shared.isIdleTimerDisabled = true` mientras se graba es el
    equivalente nativo y opcional de "no dejar que la pantalla se apague"; documentarlo.
- **Archivos**: `ios/TelepromtCam/Camara/CamaraController.swift` (+ posible
  `ios/TelepromtCam/Camara/GrabacionDelegate.swift` si se separa el delegate).
- **Definición de Hecho**:
  - [x] `xcodebuild ... build` → `** BUILD SUCCEEDED **`, 0 errores.
  - [x] Revisión de código: `cambiarLente` usa `beginConfiguration/commitConfiguration`, remueve el
    input viejo antes de agregar el nuevo, y ante fallo restaura el input anterior (sin dejar la
    sesión sin cámara); `iniciarGrabacion`/`detenerGrabacion` son idempotentes respecto al estado
    (`estaGrabando`) y el delegate entrega URL/errores.
  - [x] Grabar → detener → grabar de nuevo es posible sin reconfigurar toda la sesión (verificable
    por lógica de estado en el código).
  - [ ] Prueba visual/funcional (grabar un clip real, cambiar de lente y ver el cambio):
    **la hace el usuario** en iPhone real (el simulador no tiene cámara).
- **Evidencia del verificador**: Re-verificado con `xcodebuild` independiente → `** BUILD SUCCEEDED **`.
  Confirmado por grep y lectura de `CamaraController.swift`: `cambiarLente(a:)` hace
  `removeInput(entradaAnterior)` ANTES de `addInput(entradaNueva)`, y si `canAddInput` falla para la
  nueva, reintenta `addInput(entradaAnterior)` para no dejar la sesión sin video — patrón defensivo
  correcto. `iniciarGrabacion()`/`detenerGrabacion()` usan `guard !movieFileOutput.isRecording` /
  `guard movieFileOutput.isRecording` respectivamente, así que llamadas repetidas no rompen el
  estado. El `AVCaptureMovieFileOutput` se agrega una sola vez en `configurarSesion()` — grabar
  varias veces reutiliza el mismo output, sin reconfigurar la sesión completa. `isIdleTimerDisabled`
  usado como buena práctica (no como mitigación de un bug, comentario explícito distinguiendo esto
  del hack de timeslice+WakeLock de la web, tal como pedía la lección anotada). **Nota importante**:
  el simulador no tiene cámara física — grabar un clip real, reproducirlo, y cambiar de lente en
  vivo quedan pendientes de confirmación por el usuario en un iPhone real. Con esto se cierra la
  Fase 12 (Cámara nativa).

---

## Fase 13 — Ajustes y configuración (con calidad de cámara y fps — requisito nuevo del usuario)

### ✅ T19. Modelo de ajustes + persistencia en UserDefaults

- **Alcance**:
  - INCLUYE: en `ios/TelepromtCam/Ajustes/`, un tipo `AjustesStore` (`@Observable`) que centraliza y
    persiste en `UserDefaults` (equivalente nativo del `localStorage` de la web) TODAS las
    preferencias:
    - **Calidad de cámara** (requisito nuevo explícito): un enum `CalidadCamara` mapeado a
      `AVCaptureSession.Preset` (p. ej. `.hd1920x1080`, `.hd1280x720`, `.hd4K3840x2160` si el
      dispositivo lo soporta, `.high`) con un valor legible para UI.
    - **FPS** (requisito nuevo explícito): un enum/lista `FPS` (p. ej. 24/30/60) que luego se aplica
      vía `activeVideoMinFrameDuration`/`activeVideoMaxFrameDuration` validando contra
      `activeFormat.videoSupportedFrameRateRanges` (la validación se implementa en T20; aquí solo el
      dato persistido).
    - **Lente** por defecto (frontal/trasera).
    - **Tipografía**: tamaño de fuente, color del texto (guardar como componentes o hex).
    - **Fondo del texto**: opacidad 0–1.
    - **Velocidad base del teleprompter** en px/s (rango sugerido 12–100 como en la web T15b, default 24).
    - Valores por defecto sensatos y migración/carga segura (si falta una clave, usa el default sin
      crashear — equivalente a la defensa `acotar...` de la web).
  - NO INCLUYE: la UI de ajustes (T20), aplicar los valores a la sesión/teleprompter (T20/T21). Solo
    el modelo de datos observable + persistencia + defaults.
- **Archivos**: `ios/TelepromtCam/Ajustes/AjustesStore.swift`,
  `ios/TelepromtCam/Ajustes/CalidadCamara.swift`, `ios/TelepromtCam/Ajustes/FPS.swift` (o todo en un
  archivo si el constructor prefiere; documentar).
- **Definición de Hecho**:
  - [x] `xcodebuild ... build` → `** BUILD SUCCEEDED **`, 0 errores.
  - [x] Revisión de código: cada propiedad se lee/escribe en `UserDefaults` con clave estable; faltas
    de clave caen a default sin crash; los enums de calidad y fps existen y mapean a los tipos de
    AVFoundation correctos.
  - [x] Existe un único punto (`AjustesStore`) del que dependen las pantallas — no hay lectura directa
    dispersa de `UserDefaults` en la UI (verificable por revisión).
- **Evidencia del verificador**: Re-verificado con `xcodebuild` independiente → `** BUILD SUCCEEDED **`.
  `grep -rn "UserDefaults" ios/TelepromtCam --include="*.swift"` confirma que el único uso real está
  en `AjustesStore.swift` (las otras dos apariciones en `CalidadCamara.swift`/`FPS.swift` son solo
  comentarios). Buena decisión de diseño no reportada como riesgo: usa
  `defaults.object(forKey:) != nil` antes de confiar en `.double`/`.integer` (evita el bug clásico de
  que UserDefaults devuelve `0` silenciosamente para una clave ausente, que rompería el "cae a
  default" si no se hiciera así). Claves centralizadas en un enum privado evita typos entre lectura
  y escritura. Color persistido como 4 componentes RGBA (no hex) — buena decisión, sin pérdida de
  precisión. Enums de calidad/fps con raw values estables y `init?(rawValue:)` con fallback a
  default si el valor guardado no matchea. Con esto queda listo el modelo para que T20 construya la
  UI sobre él.

### ✅ T20. Pantalla de Ajustes en SwiftUI (calidad, fps, lente, tipografía, opacidad, velocidad) con preview en vivo y aplicación a la sesión

- **Alcance**:
  - INCLUYE: una vista `PantallaAjustes` (SwiftUI `Form`/`List`) enlazada a `AjustesStore` con:
    - **Selector de calidad de cámara** (Picker con las opciones de `CalidadCamara`) que al cambiar
      aplica `session.sessionPreset` (dentro de `begin/commitConfiguration`), validando que el preset
      sea soportado (`session.canSetSessionPreset`) y cayendo a uno soportado si no.
    - **Selector de fps** (Picker) que aplica `activeVideoMinFrameDuration`/`MaxFrameDuration` al
      `AVCaptureDevice`, **validando contra `activeFormat.videoSupportedFrameRateRanges`** — si el fps
      pedido no es soportado por el formato/preset activo, ajustar al más cercano soportado y no
      crashear (esto es un punto clásico de crash en AVFoundation; anotado explícito).
    - **Selector de lente** frontal/trasera (reusa `cambiarLente` de T18).
    - **Tamaño de fuente** (Slider), **color de texto** (ColorPicker), **opacidad de fondo** (Slider),
      **velocidad base** (Slider 12–100) — todos enlazados a `AjustesStore` y persistidos.
    - **Preview en vivo** dentro del panel: un texto de muestra que refleja tamaño/color/opacidad y se
      desplaza animado a la velocidad configurada (equivalente al preview de T13 en la web), aislado
      del teleprompter real (su propia animación).
  - NO INCLUYE: el teleprompter real (T21), el flujo de grabación (T24). El overlay real puede aún no
    existir cuando se hace esta tarea; el preview es autocontenido.
- **Archivos**: `ios/TelepromtCam/Ajustes/PantallaAjustes.swift`,
  `ios/TelepromtCam/Ajustes/PreviewAjustes.swift`, y ajustes menores en `CamaraController` para
  exponer `aplicarCalidad`/`aplicarFPS` de forma segura.
- **Definición de Hecho**:
  - [x] `xcodebuild ... build` → `** BUILD SUCCEEDED **`, 0 errores.
  - [x] Revisión de código: el cambio de fps valida contra `videoSupportedFrameRateRanges` y NUNCA
    asigna un frame duration fuera de rango (defensa anti-crash explícita); el cambio de preset usa
    `canSetSessionPreset`; ambos dentro de `begin/commitConfiguration` y con `lockForConfiguration`
    donde AVFoundation lo exige.
  - [x] Los controles están enlazados a `AjustesStore` y persisten (revisión + build).
  - [x] El preview en vivo se anima con su propia velocidad y no toca el estado del teleprompter real.
  - [ ] Prueba visual (mover sliders y ver el efecto, cambio real de calidad/fps en la imagen):
    **la hace el usuario** (calidad/fps sobre imagen real solo se aprecian en iPhone físico).
- **Evidencia del verificador**: Re-verificado con `xcodebuild` independiente → `** BUILD SUCCEEDED **`.
  Leí `aplicarFPS`/`aplicarCalidadCamara` línea por línea en `CamaraController.swift`: `aplicarFPS`
  busca primero un rango que CONTENGA el fps pedido (`contains`); si ninguno lo contiene, calcula el
  clamp más cercano entre TODOS los rangos disponibles ANTES de tocar `lockForConfiguration()` — el
  valor que finalmente se asigna a `activeVideoMinFrameDuration`/`MaxFrameDuration` siempre viene de
  ese cálculo defensivo, nunca del valor crudo pedido por el usuario; `lockForConfiguration()` está
  en un `do/catch` con `defer { unlockForConfiguration() }`, sin camino de crash. `aplicarCalidadCamara`
  verifica `canSetSessionPreset` ANTES de `beginConfiguration()` — si no es soportado, retorna sin
  tocar la sesión y expone un mensaje legible vía `errorGrabacion`. Ambos métodos corren en
  `colaSesion` (no en main), consistente con T17/T18. `PreviewAjustes.swift` usa `TimelineView` con
  su propio cálculo de offset basado en tiempo — no importa nada de un módulo de teleprompter real
  (que aún no existe, T21 lo construye después), confirmado por ausencia de imports cruzados. **Nota
  importante**: el simulador no tiene cámara física — el efecto visual real de cambiar calidad/fps
  sobre la imagen en vivo queda pendiente de confirmación del usuario en un iPhone real; la lógica
  de validación anti-crash es sólida por revisión de código pero solo un dispositivo real confirma
  los rangos reales soportados. Con esto se cierra la Fase 13 (Ajustes y configuración).

---

## Fase 14 — Teleprompter (overlay + scroll)

### ✅ T21. Overlay de texto sobre la cámara + scroll automático a velocidad configurable

- **Alcance**:
  - INCLUYE: en `ios/TelepromtCam/Teleprompter/`, una vista `OverlayTeleprompter` superpuesta sobre el
    preview de cámara (SwiftUI `ZStack`: preview al fondo, texto encima en la franja superior, cerca
    del lente frontal — equivalente al T13 de la web), con el fondo translúcido/opaco y color/tamaño
    tomados de `AjustesStore`. Un `TeleprompterController` (`@Observable`) que maneja el
    desplazamiento vertical automático con **delta de tiempo** (usar `TimelineView(.animation)` o un
    `CADisplayLink` — decide el constructor; el desplazamiento debe ser proporcional al delta de
    tiempo real, no al conteo de frames, exactamente como la web con `requestAnimationFrame`), a la
    velocidad base de `AjustesStore` multiplicada por un `factorVelocidad` (que T22 controlará por
    voz; aquí default 1.0). Métodos `iniciar()`, `pausar()`, `reiniciar()`, `setVelocidad(factor)`.
    Se detiene solo al llegar al final del texto (clamp).
  - NO INCLUYE: control por voz (T22), editor (T23), acople a grabar (T24). El texto de arranque puede
    ser un guion de ejemplo hardcodeado hasta que T23 lo reemplace.
  - **Lección de la web (anotada)**: el scroll DEBE basarse en delta de tiempo, no en conteo de
    frames, o acelera/frena con la carga (ya validado en la web, T5). `setVelocidad(factor)` debe ser
    reactivo en vivo (leerse en cada frame), no reiniciar la animación.
- **Archivos**: `ios/TelepromtCam/Teleprompter/OverlayTeleprompter.swift`,
  `ios/TelepromtCam/Teleprompter/TeleprompterController.swift`,
  `ios/TelepromtCam/App/ContentView.swift` (compone overlay sobre preview).
- **Definición de Hecho**:
  - [x] `xcodebuild ... build` → `** BUILD SUCCEEDED **`, 0 errores.
  - [x] Revisión de código: el avance usa delta de tiempo real; `setVelocidad` es reactivo sin
    reiniciar; el scroll clampa al final y se auto-detiene; el overlay respeta safe areas
    (`.safeAreaInset` o `env`-equivalente) y no tapa los controles.
  - [x] `setVelocidad(0)` detiene el avance y un factor mayor lo acelera proporcionalmente (verificable
    por lógica; el punto de acople real llega en T22).
  - [ ] Prueba visual (fluidez del scroll sobre el video, legibilidad del overlay):
    **la hace el usuario**.
- **Evidencia del verificador**: Re-verificado con `xcodebuild` independiente → `** BUILD SUCCEEDED **`.
  Leí `TeleprompterController.swift` línea por línea: `avanzar(hasta:)` calcula
  `deltaSegundos = ahora.timeIntervalSince(anterior)` y avanza
  `velocidadBase * factorVelocidad * deltaSegundos` — delta de tiempo real, exactamente el patrón
  validado en la web T5, no conteo de frames. Detalle bien pensado que el reporte del constructor
  explicó: el primer tick tras `iniciar()`/`reiniciar()` NO avanza (solo fija la referencia de
  tiempo), evitando el bug típico de "salto gigante" por delta acumulado desde una pausa larga —
  algo que ni la versión web tuvo que resolver explícitamente. `setVelocidad()` solo actualiza
  `factorVelocidad` (clamped a ≥0), leído en vivo dentro de `avanzar()` — cambiarlo no reinicia
  `ultimoTimestamp` ni interrumpe nada. El clamp de fin (`posicionMaximaPx`) se recalcula con
  `actualizarAlturas()` y para `estaReproduciendo` automáticamente al alcanzarlo. `texto` con
  `didSet` que reinicia el scroll al cambiar — deja el gancho listo para que T23 lo use sin fricción.
  **Nota importante**: sin GUI interactiva en este entorno, no se pudo confirmar visualmente la
  fluidez del scroll sobre el video real ni la legibilidad del overlay — el usuario debe confirmarlo
  en simulador o iPhone real. Con esto se cierra la Fase 14 (Teleprompter).

---

## Fase 15 — Detección de voz (AVAudioEngine) y enganche a la velocidad

### ✅ T22. VAD por energía RMS con histéresis (AVAudioEngine) + enganche voz→velocidad del scroll

- **Alcance**:
  - INCLUYE: en `ios/TelepromtCam/Voz/`, un `VozController` (`@Observable`) que instala un tap
    (`installTap(onBus:)`) sobre el `inputNode` de un `AVAudioEngine`, calcula la **energía RMS** del
    buffer en cada callback, y clasifica "habla"/"silencio" con **histéresis de dos umbrales**
    (umbral de entrada > umbral de salida, para no parpadear) — mismo enfoque conceptual que la web
    (ADR "no Web Speech API", se mantiene). Expone `nivel` (0–1) y `estaHablando`. Engancha el estado
    a `TeleprompterController.setVelocidad`: en silencio factor 0 (texto detenido); hablando, el
    factor escala con el nivel dentro de un rango mín/máx, con suavizado (interpolación) para no
    saltar. Manejo de la sesión de audio (`AVAudioSession` categoría `.playAndRecord`/`.record`
    compatible con la grabación simultánea de la cámara) y arranque tras permiso de micrófono.
  - NO INCLUYE: reconocimiento de palabras (fuera del ADR), UI de calibración avanzada. Un indicador
    de nivel simple para calibrar es opcional.
  - **LECCIÓN CRÍTICA DE LA WEB — el constructor DEBE respetarla para no repetir el bug (T14):** en la
    web, el bug real de "no sigue la velocidad al hablar" NO fue solo umbrales mal calibrados, sino un
    **error de diseño en el mapeo nivel→factor**: se multiplicaba el `nivel` RMS crudo (que en la
    práctica vive en un rango pequeño, ~0.015–0.15) directamente por `(FACTOR_MAX − FACTOR_MIN)`
    asumiendo que `nivel` ya estaba normalizado en [0,1] — con valores tan chicos casi toda la
    variación se perdía y el factor quedaba pegado cerca del mínimo sin importar cómo hablara el
    usuario. La corrección fue **remapear el `nivel` desde su rango realista
    (`umbralEntrada`..`nivelHablaMaxEsperado`, p. ej. ~0.15) a una fracción 0–1 ANTES de aplicar la
    fórmula del factor**. En Swift, el constructor debe: (a) NO asumir que el RMS crudo está en [0,1];
    (b) implementar explícitamente ese remapeo de rango realista → [0,1] antes de escalar al rango de
    factor; (c) dejar los umbrales y el `nivelHablaMaxEsperado` como constantes ajustables con
    comentario; (d) documentar que la calibración final es a ciegas sin micrófono real en este
    entorno y probablemente necesite un ajuste tras la primera prueba del usuario en iPhone.
- **Archivos**: `ios/TelepromtCam/Voz/VozController.swift`, y el punto de composición
  (`ContentView`/coordinador) que conecta `VozController` con `TeleprompterController`.
- **Definición de Hecho**:
  - [x] `xcodebuild ... build` → `** BUILD SUCCEEDED **`, 0 errores.
  - [x] Revisión de código: histéresis de dos umbrales aplicada; **el mapeo nivel→factor remapea el
    rango realista a [0,1] antes de escalar** (la lección de T14 está implementada, no repetida);
    suavizado presente; factor recortado a [0, máx] sin retroceder; la `AVAudioSession` es compatible
    con grabar video simultáneamente (no roba/rompe el input de la cámara).
  - [x] En silencio el factor converge a 0; hablando más fuerte el factor sube dentro del rango
    (verificable por lógica de la fórmula, no por audio real).
  - [ ] Prueba funcional (que el texto siga el ritmo real de la voz, calibración de umbrales):
    **la hace el usuario** en iPhone real (no hay micrófono en este entorno; los valores casi seguro
    necesitarán un ajuste tras la primera prueba).
- **Evidencia del verificador**: Re-verificado con `xcodebuild` independiente → `** BUILD SUCCEEDED **`.
  Leí `VozController.swift` línea por línea, con especial atención en `procesarNivel()` y
  `remapearNivelAFraccion()` — **confirmado que el remapeo ocurre estrictamente ANTES de la fórmula
  del factor**: `remapearNivelAFraccion(rms)` se llama primero, y solo su resultado (`fraccionRemapeada`,
  ya en [0,1]) se usa en `factorMinimoHablando + fraccionRemapeada * (factorMaximoHablando -
  factorMinimoHablando)` — el `nivel`/`rms` crudo NUNCA se multiplica directo contra el rango del
  factor. Esta es exactamente la lección crítica bien aplicada, con el comentario en el código
  citando el bug original de T14 de la web. Histéresis de dos umbrales confirmada como máquina de
  estados (`if estaHablando { caer bajo salida } else { subir sobre entrada }`) — no hay camino de
  parpadeo con un solo umbral. Suavizado exponencial presente (`pesoSuavizado=0.15`, mismo valor que
  la web). Recorte final `max(0, min(factorMaximoHablando, factorSuavizado))` confirmado como última
  línea antes de `setVelocidad()` — nunca negativo, nunca excede el máximo. `AVAudioSession`
  configurada con `.playAndRecord`/`.videoRecording`/`.mixWithOthers`, con el razonamiento de
  coexistencia con `AVCaptureSession` bien documentado en el código (no llama `setActive(false)`
  mientras la cámara está activa). Reutiliza el permiso de micrófono ya concedido por
  `CamaraController` en vez de pedirlo de nuevo — buena decisión, evita un segundo prompt redundante.
  **Nota importante**: sin micrófono real en este entorno, la calibración (umbrales 0.02/0.01,
  `nivelHablaMaxEsperado`=0.15, rango de factor 0.7-1.8) es una estimación basada en los valores que
  la web terminó usando tras dos rondas reales — el propio código lo documenta con la misma
  honestidad que la web. Es muy probable que necesite un tercer ajuste tras la primera prueba del
  usuario en iPhone real, pero al menos el ERROR DE DISEÑO que causó el bug más grave de la web
  (T14) no está presente aquí desde el principio. Con esto se cierra la Fase 15 (Detección de voz).

---

## Fase 16 — Editor del guion

### ✅ T23. Editor de guion con persistencia

- **Alcance**:
  - INCLUYE: en `ios/TelepromtCam/Editor/`, una vista `PantallaEditor` con un `TextEditor` de SwiftUI
    donde el usuario escribe/pega el guion; persistencia del guion (un solo guion, como en la web v1)
    en `UserDefaults` (o `FileManager`/Documentos si el texto crece — decide el constructor y lo
    documenta; el ADR permite ambos). Carga automática al abrir; al guardar, el `TeleprompterController`
    (T21) toma el texto nuevo y reinicia su scroll. Guion de ejemplo por defecto en el primer uso
    (localStorage vacío → texto de ejemplo, como la web T6).
  - NO INCLUYE: múltiples guiones, títulos, nube (fuera de alcance v1, igual que la web).
- **Archivos**: `ios/TelepromtCam/Editor/PantallaEditor.swift`,
  `ios/TelepromtCam/Editor/GuionStore.swift` (persistencia), integración con `TeleprompterController`.
- **Definición de Hecho**:
  - [x] `xcodebuild ... build` → `** BUILD SUCCEEDED **`, 0 errores.
  - [x] Revisión de código: guardar persiste bajo clave estable y sobrescribe (no acumula copias);
    carga al abrir; primer uso cae a un guion de ejemplo sin crash; guardar actualiza el texto del
    teleprompter.
  - [ ] Prueba visual (escribir, guardar, reabrir y ver el guion; que el teleprompter lo muestre):
    **la hace el usuario** (persistencia y flujo verificables en simulador GUI por el usuario).
- **Evidencia del verificador**: Re-verificado con `xcodebuild` independiente → `** BUILD SUCCEEDED **`.
  `GuionStore.swift` confirmado: clave estable `editor.guion` vía enum privado (mismo patrón que
  `AjustesStore` de T19), `guardar()` hace `set(_:forKey:)` simple — sobrescribe, no acumula.
  `ContentView.init()` decide el guion inicial con `if let` sobre `GuionStore().cargar()`, sin
  forzar unwrap — primer uso (nil) cae al `guionDeEjemplo` de T21 sin riesgo de crash. `PantallaEditor`
  guarda y además asigna `teleprompter.texto = textoEditado`, reusando el `didSet` de T21 que ya
  reinicia el scroll — sin duplicar esa lógica. Decisión razonable de agregar un botón mínimo
  "Editar guion" + `.sheet` en ContentView para que el editor sea alcanzable, documentando
  explícitamente que T24 reestructurará esos controles secundarios (habilitación condicionada a
  cámara activa, igual que T12 de la web) — evita que T23 quede huérfano de UI sin invadir el
  alcance de T24. **Nota importante**: sin GUI interactiva en este entorno, escribir/guardar/
  reabrir y confirmar que el teleprompter muestra el guion nuevo queda pendiente de la prueba
  visual del usuario. Con esto se cierra la Fase 16 (Editor).

---

## Fase 17 — Flujo de grabación completo (equivalente a T12/T14 de la web)

### ✅ T24. Flujo de grabación: botón grande, indicador visible, modal obligatorio Descargar(a Fotos)/Descartar

- **Alcance**:
  - INCLUYE:
    1. **Botón principal grande**: al arrancar es "Activar cámara"; con la cámara activa se convierte
       en el botón grande "Grabar"/"Detener" (equivalente al flujo T12).
    2. **Cámara habilita todo**: controles secundarios (abrir ajustes, abrir editor) deshabilitados
       hasta que la cámara y el micrófono estén activos; al activar cámara, se arranca también la
       detección de voz (T22) y el modo voz queda activo por defecto (como T12).
    3. **Grabar controla el teleprompter**: al iniciar grabación se llama `TeleprompterController.iniciar()`
       (con enganche de voz de T22 controlando la velocidad); al detener, `pausar()`.
    4. **Indicador de "grabando" visible**: punto rojo sólido y brillante con parpadeo y fondo oscuro
       semitransparente para contraste sobre cualquier video (equivalente a T14/T15a; asegurarse de
       que solo aparece mientras `estaGrabando == true`).
    5. **Modal obligatorio de resultado**: al detener la grabación, un overlay a pantalla completa
       (`.fullScreenCover`) con un reproductor (`VideoPlayer` de AVKit) del clip grabado y EXACTAMENTE
       dos acciones: **"Guardar en Fotos"** (guarda el archivo en el carrete vía `PHPhotoLibrary`
       —`performChanges` con `creationRequestForAssetFromVideo`— pidiendo el permiso
       `NSPhotoLibraryAddUsageDescription` ya declarado en T16; "descargar" en iOS = guardar al
       carrete) y **"Descartar y grabar de nuevo"** (borra el archivo temporal, no guarda). El modal NO
       se puede cerrar de otra forma (sin swipe-to-dismiss, sin tap fuera) — obliga a elegir, para no
       perder por accidente lo grabado (equivalente a T14). Cualquiera de las dos deja la app lista
       para grabar de nuevo sin reiniciar.
  - NO INCLUYE: edición/recorte del video, compartir a redes, elegir bitrate. La calidad/fps ya vienen
    de T20.
- **Archivos**: `ios/TelepromtCam/App/ContentView.swift`,
  `ios/TelepromtCam/Camara/ModalResultado.swift`, `ios/TelepromtCam/Comun/GuardadoFotos.swift`
  (wrapper de `PHPhotoLibrary`), ajustes en `CamaraController`/`TeleprompterController` para el acople.
- **Definición de Hecho**:
  - [x] `xcodebuild ... build` → `** BUILD SUCCEEDED **`, 0 errores.
  - [x] Revisión de código: el modal es no-descartable salvo por sus dos botones; "Guardar en Fotos"
    usa `PHPhotoLibrary.performChanges` y maneja el permiso (incluye el caso denegado con mensaje
    legible, sin crash); "Descartar" borra el temporal; ambos dejan la app lista para regrabar;
    iniciar/detener grabación arranca/para el scroll; el indicador rojo solo aparece grabando.
  - [x] `swiftc`/build confirman que no hay uso de API de Fotos sin el usage string (el string existe
    desde T16).
  - [ ] Prueba funcional completa (grabar, ver el modal, guardar al carrete y confirmarlo en Fotos,
    descartar): **la hace el usuario** en iPhone real (requiere cámara y carrete reales).
- **Evidencia del verificador**: Re-verificado con `xcodebuild` independiente → `** BUILD SUCCEEDED **`.
  `ModalResultado.swift` revisado línea por línea: presentado con `.fullScreenCover` (sin
  swipe-to-dismiss por defecto, a diferencia de `.sheet`), sin `.interactiveDismissDisabled`
  adicional porque no hace falta, sin botón X, sin gesto de tap-fuera — el comentario del propio
  código lo confirma como decisión deliberada. Los dos botones son los ÚNICOS caminos que llaman
  `camaraController.limpiarUltimaGrabacion()` (que colapsa el binding de `.fullScreenCover` a
  `false`) — confirmado por grep, no hay una tercera vía de cierre. `GuardadoFotos.guardarVideo`
  usa `PHPhotoLibrary.requestAuthorization(for: .addOnly)` solo si `.notDetermined`, y el resultado
  se modela como enum (`.exito`/`.permisoDenegado`/`.error`) — en `.permisoDenegado` el modal se
  queda abierto con mensaje legible (no cierra silenciosamente ni crashea), dejando al usuario
  decidir entre reintentar o descartar. El indicador rojo en `ContentView.swift` está envuelto en
  `if camara.estaGrabando { Circle()... }` — la vista NO EXISTE en el árbol cuando no está grabando
  (a diferencia del bug de la web T15a, donde `display:flex` con alta especificidad CSS ignoraba el
  atributo `hidden`; en SwiftUI un `if` condicional no tiene ese riesgo de especificidad, la vista
  simplemente no se construye). `.onChange(of: camara.estaGrabando)` llama `teleprompter.pausar()`
  cubriendo tanto el stop manual como el que dispara el delegate de `AVCaptureFileOutputRecordingDelegate`
  — un solo punto de verdad, sin duplicar la lógica de parada. Controles secundarios (ajustes,
  editor) con `.disabled(!camaraLista)`. **Nota importante**: sin cámara/mic/carrete de Fotos reales
  en este entorno, el flujo funcional completo (grabar, ver el modal con el clip real, guardar al
  carrete y confirmarlo en la app Fotos, descartar) queda pendiente de la prueba del usuario en un
  iPhone real. Con esto se cierra la Fase 17 (Flujo de grabación) — la app nativa ya tiene toda la
  funcionalidad central equivalente a la web (T1-T15b).

---

## Fase 18 — Assets para App Store

### ✅ T25. App icon set completo + launch screen

- **Alcance**:
  - INCLUYE:
    1. **App icon set completo**: a partir de un master 1024×1024 (el constructor genera un ícono
       simple y limpio acorde a "TelepromtCam" — cámara + texto/teleprompter; sin texto pequeño
       ilegible, sin esquinas redondeadas propias —iOS las aplica—, sin canal alfa/transparencia en el
       1024 de App Store), generar TODOS los tamaños que Xcode/App Store exigen usando **`sips`**
       (herramienta nativa de macOS, disponible en el entorno — se confirmó; equivalente al script de
       generación de iconos PWA de T11 pero con `sips` en vez de Python, documentado). Poblar
       `Assets.xcassets/AppIcon.appiconset` con `Contents.json` correcto. **Nota**: Xcode 15+/iOS 17
       admite el **single-size 1024 app icon** (un solo asset 1024 y Xcode deriva el resto) — el
       constructor puede usar esa vía moderna (más simple y robusta) y documentar que la usó; si opta
       por el set completo clásico, debe cubrir todos los tamaños del `Contents.json`.
    2. **Launch screen**: una `LaunchScreen` (storyboard mínimo o la clave `UILaunchScreen` en
       Info.plist con color de fondo + imagen/nombre de la app centrado) que no muestre contenido
       dinámico (Apple lo exige simple), coherente con el color de acento de la app.
  - NO INCLUYE: screenshots de App Store (esos los genera el usuario desde el simulador, van en la
    checklist manual), arte de marketing adicional.
  - **Herramienta documentada**: `sips` (nativa macOS) para redimensionar el master 1024 a los tamaños
    del appiconset — se eligió porque PIL/ImageMagick/rsvg NO están en el entorno pero `sips` sí (se
    verificó), mismo espíritu que T11 (usar lo disponible en el sistema, documentándolo).
- **Archivos**: `ios/TelepromtCam/App/Assets.xcassets/AppIcon.appiconset/` (PNGs + `Contents.json`),
  `ios/TelepromtCam/App/LaunchScreen.storyboard` (o entrada `UILaunchScreen` en Info.plist),
  `ios/AppStore/icono-master-1024.png` (el master, para regenerar).
- **Definición de Hecho**:
  - [x] `xcodebuild ... build` → `** BUILD SUCCEEDED **`, 0 errores, y el catálogo de assets compila
    sin warnings de "unassigned children" / iconos faltantes (Xcode advierte si falta algún tamaño
    requerido — la ausencia de esos warnings es el criterio verificable).
  - [x] El PNG 1024 del App Store NO tiene canal alfa (verificable con `sips -g hasAlpha` → `no`).
  - [x] Todos los PNGs generados tienen las dimensiones que declara su `Contents.json` (verificable con
    `sips -g pixelWidth -g pixelHeight` por archivo).
  - [x] La launch screen está referenciada correctamente y el build la reconoce (sin warning de launch
    screen faltante).
  - [ ] Revisión visual del ícono (que se vea bien y no genérico): **la hace el usuario**.
- **Evidencia del verificador**: Re-verificado con `xcodebuild` independiente → `** BUILD SUCCEEDED **`,
  grep de "warning" sobre el log completo del build → 0 resultados. `sips -g hasAlpha` sobre el
  master 1024 → `no`. `sips -g pixelWidth -g pixelHeight` sobre el icono del appiconset → 1024x1024,
  coincide con Contents.json. `plutil -p` sobre el Info.plist efectivo del build confirma
  `UILaunchScreen` presente y `CFBundleDisplayName`/`CFBundleIdentifier` intactos desde T16-T24 (el
  cambio de Info.plist generado a físico no rompió nada de lo ya configurado). **Verificación
  adicional que hice yo mismo, no solo confiar en el reporte**: el constructor tuvo que hacer un
  cambio estructural delicado (pasar de `GENERATE_INFOPLIST_FILE` puro a un `Info.plist` físico +
  una `PBXFileSystemSynchronizedBuildFileExceptionSet` en el pbxproj, porque una clave anidada como
  `UILaunchScreen.UIColorName` no se puede expresar de forma confiable solo con `INFOPLIST_KEY_*`).
  Confirmé por grep que la excepción está bien acotada (excluye únicamente `App/Info.plist` de las
  Copy Bundle Resources del grupo sincronizado) — agregar cualquier otro `.swift` nuevo dentro de
  `ios/TelepromtCam/` sigue sin requerir tocar el pbxproj, la propiedad clave de T16 no se perdió.
  Ícono generado con un escritor de PNG puro en Python (mismo enfoque que T11 de la web, sin
  ImageMagick/PIL disponibles): fondo azul sólido + cuerpo de cámara + lente + barras decrecientes
  sugiriendo texto de teleprompter — simple y sin alfa, cumple los requisitos de Apple. **Nota**: la
  apreciación visual final de si el ícono "se ve bien" la debe hacer el usuario — es subjetivo y no
  verificable por código; si no le gusta, es fácil regenerar el master. Con esto se cierra la Fase 18
  (Assets para App Store).

---

## Fase 19 — Metadata de App Store Connect (texto real, listo para copiar/pegar)

### ✅ T26. Metadata de App Store Connect + borrador de política de privacidad

- **Alcance**:
  - INCLUYE: crear en `ios/AppStore/` archivos de texto con el **contenido real** (NO placeholders)
    listo para copiar/pegar en App Store Connect:
    - `metadata.md` con: **Nombre** (TelepromtCam), **Subtítulo** (≤30 caracteres, redactado),
      **Descripción** completa (redactada, describiendo teleprompter + grabación + control por voz +
      ajustes de calidad/fps/tipografía + privacidad total sin backend), **Palabras clave** (≤100
      caracteres separadas por coma, redactadas: teleprompter, guion, grabar video, voz, cámara,
      prompter, etc.), **Categoría** sugerida (primaria y secundaria — decidir y justificar, p. ej.
      Fotografía y vídeo / Productividad), **Texto "Qué hay de nuevo" (v1.0)** redactado,
      **URL de soporte** y **URL de marketing/privacidad**.
    - **Decisión de URLs (la toma el arquitecto aquí)**: reusar el mismo GitHub Pages del repo como
      base — política de privacidad en `https://juandiegorodri.github.io/teleprompter-app/privacidad.html`
      y soporte en la misma URL raíz `https://juandiegorodri.github.io/teleprompter-app/` (o una
      `soporte.html`). El constructor **crea el archivo `privacidad.html`** (y opcional `soporte.html`)
      **en la RAÍZ del repo** (no dentro de `ios/`), porque GitHub Pages sirve desde la raíz de `main`
      (ADR de hosting) — así la URL de privacidad queda viva sin infraestructura nueva. Si el usuario
      prefiere otra URL, es un cambio de una línea; se deja anotado.
    - `politica-privacidad.md` (fuente del contenido) + su render `privacidad.html`: borrador de
      **política de privacidad simple y veraz**: la app usa **cámara, micrófono y (para guardar)
      acceso de escritura al carrete de Fotos**; **NO** hay analítica, **NO** hay backend, **NO** se
      recopila ni transmite ningún dato personal — los videos y el guion quedan **solo en el
      dispositivo del usuario**. Debe decir esto de forma explícita (es exactamente lo que Apple
      pregunta en el cuestionario de privacidad y lo que hace la app).
    - `resumen-privacidad-apple.md`: un resumen de cómo responder el **cuestionario de privacidad de
      App Store Connect** ("App Privacy") coherente con lo anterior — esencialmente "Data Not
      Collected" para todas las categorías (dejarlo escrito para que el usuario lo copie al llenar el
      formulario, que es parte de su checklist manual).
  - NO INCLUYE: crear la ficha en App Store Connect (lo hace el usuario), screenshots.
- **Archivos**: `ios/AppStore/metadata.md`, `ios/AppStore/politica-privacidad.md`,
  `ios/AppStore/resumen-privacidad-apple.md`, `privacidad.html` (raíz del repo, para GitHub Pages),
  opcional `soporte.html` (raíz).
- **Definición de Hecho**:
  - [x] `metadata.md` contiene TODOS los campos listados con texto real redactado (no "TODO"/
    placeholder), respetando los límites de caracteres de App Store (subtítulo ≤30, keywords ≤100) —
    verificable contando caracteres.
  - [x] La política de privacidad afirma explícitamente: usa cámara/mic/escritura a Fotos; sin
    analítica; sin backend; datos solo en el dispositivo. Coherente con lo que el código realmente
    hace (verificable cruzando con los usage strings de T16 y el uso de `PHPhotoLibrary` de T24).
  - [x] `privacidad.html` es HTML válido y quedará servible desde GitHub Pages en la URL declarada en
    `metadata.md` (la publicación real —push— la confirma el flujo normal del repo; el archivo existe
    en la raíz).
  - [x] `resumen-privacidad-apple.md` mapea cada categoría del cuestionario de Apple a "no se recopila"
    con una nota de por qué.
  - [ ] Revisión editorial final del texto de marketing: **la hace el usuario** (puede querer ajustar
    el tono); el contenido queda completo y usable tal cual.
- **Evidencia del verificador**: Verificado independientemente con `wc -c`: subtítulo "Teleprompter y
  grabación" = 25 bytes (24 caracteres visibles, la diferencia es la tilde de "grabación" en UTF-8),
  bajo el límite de 30; palabras clave = 97 bytes, bajo el límite de 100. `metadata.md` completo con
  los 7 campos pedidos, todos con texto real (leído completo, sin placeholders). `privacidad.html`
  confirmado con las tres afirmaciones clave presentes (cámara/mic/Fotos, sin backend, sin
  analítica) mediante verificación de contenido. Coherencia cruzada: `NSCameraUsageDescription`/
  `NSMicrophoneUsageDescription`/`NSPhotoLibraryAddUsageDescription` (T16) y el uso exclusivo de
  escritura (`addOnly`) de `PHPhotoLibrary` en `GuardadoFotos.swift` (T24) respaldan exactamente lo
  que la política afirma — no hay contradicción entre el texto legal y lo que el código realmente
  hace. Categoría primaria/secundaria justificada con razonamiento breve. El `resumen-privacidad-apple.md`
  incluye el razonamiento correcto de por qué "User Content (Photos/Videos)" sigue siendo
  "Data Not Collected" según la definición de Apple (collection = transmisión fuera del dispositivo,
  no uso/almacenamiento local) — un matiz fácil de pasar por alto y que el constructor manejó bien.
  Pendiente explícito: el email de contacto en la política quedó como placeholder claro (depende del
  usuario) y la revisión editorial del tono de marketing la debe hacer el usuario. Con esto se cierra
  la Fase 19 (Metadata de App Store Connect).

---

## Fase 20 — Evaluación contra las App Store Review Guidelines (tarea dedicada del "evaluador")

### ✅ T27. Auditoría de App Store Review Guidelines sobre el proyecto completo

- **Alcance** *(esta es la tarea que el usuario pidió explícitamente: "corre también un evaluador".
  La ejecuta el rol VERIFICADOR del enjambre, pero como una tarea dedicada al final de la fase, no
  como la verificación de cada tarea individual)*:
  - INCLUYE: una revisión escrita del proyecto iOS completo contra las **Apple App Review Guidelines**,
    cubriendo como mínimo los motivos de rechazo comunes:
    1. **Permisos declarados vs. usados**: cada usage string de Info.plist (cámara, mic, Fotos)
       corresponde a un uso real en el código, y no hay uso de una API sensible sin su usage string
       (Guideline 5.1.1 — un usage string genérico o ausente es rechazo seguro). Cruzar Info.plist ↔
       `AVCaptureDevice`/`AVAudioEngine`/`PHPhotoLibrary`.
    2. **Completitud / sin placeholders visibles** (Guideline 2.1 / 2.3): no hay textos "lorem",
       botones muertos, pantallas vacías, ni el ícono/launch screen placeholder de T16 (deben ser los
       reales de T25).
    3. **Estabilidad**: `xcodebuild build` limpio, y smoke-launch headless en simulador sin crash de
       arranque; revisión de los puntos conocidos de crash en AVFoundation (fps fuera de rango — T20,
       permiso denegado — T17, cámara trasera ausente — T18) confirmando que se manejan sin crash.
    4. **Metadata coherente** (Guideline 2.3.x): nombre/descripción/keywords de T26 describen lo que la
       app hace; la categoría es adecuada; las URLs de soporte/privacidad resuelven.
    5. **Privacidad** (Guideline 5.1): la política de privacidad existe, es accesible por URL, y el
       "resumen-privacidad-apple" es coherente con el comportamiento real (sin recolección de datos).
    6. **Funcionalidad mínima / no "solo web"** (Guideline 4.2): confirmar que es una app nativa con
       funcionalidad propia (lo es — no es un wrapper de WKWebView, por ADR), no rechazable por 4.2.
  - Entregar un **informe escrito** en `ios/AppStore/revision-appstore.md` con: checklist de cada
    guideline revisada, hallazgos (pasa / riesgo / falla) y, si hay fallas, qué tarea/archivo
    corregir (no se corrige "de pasada" — se anota como en la sección Bugs de este archivo).
  - NO INCLUYE: enviar la app a revisión de Apple (lo hace el usuario), ni garantizar la aprobación
    (Apple decide) — es una auditoría preventiva de los rechazos comunes.
- **Archivos**: `ios/AppStore/revision-appstore.md` (informe). No modifica código (los arreglos que
  surjan se anotan y se vuelven tareas).
- **Definición de Hecho**:
  - [x] El informe cubre los 6 bloques anteriores con un veredicto por cada uno (pasa/riesgo/falla) y
    evidencia (rutas de archivo, líneas, resultado de `xcodebuild`/`simctl`).
  - [x] Cruce permisos↔uso hecho explícito: tabla de cada usage string ↔ dónde se usa en el código (o
    marcado como "declarado no usado" = quitar, para no arriesgar 5.1.1).
  - [x] Si hay hallazgos de "falla", cada uno tiene una acción concreta anotada (tarea de corrección);
    si no hay ninguno, se afirma explícitamente que no se encontraron bloqueadores de rechazo común.
  - [x] La decisión final de enviar a revisión y el juicio de Apple: **quedan del lado del usuario**.
- **Evidencia del verificador**: Informe completo escrito en `ios/AppStore/revision-appstore.md`,
  cubriendo los 6 bloques con veredicto PASA en todos, respaldado por evidencia real re-verificada
  en esta misma auditoría (no solo reciclando resultados de tareas anteriores): `xcodebuild` limpio
  (0 errores, 0 warnings), smoke-launch real en simulador con PID confirmado vivo, tabla de cruce
  permisos↔uso con los 3 usage strings de Info.plist mapeados a su uso real en el código (sin
  huérfanos en ninguna dirección), grep confirmando ausencia de placeholders/TODOs/lorem, ausencia
  de `URLSession`/`URLRequest`/`WKWebView` en todo el proyecto (respalda tanto la política de
  privacidad como el no-rechazo por Guideline 4.2), y revisión de los 5 puntos clásicos de crash de
  AVFoundation confirmando que todos están defendidos por el código de T17/T18/T20/T24. No se
  encontraron hallazgos de "falla" — no hay tareas de corrección pendientes. Riesgos residuales
  (calibración de voz, camino feliz de cámara/Fotos) documentados como límites inherentes de no
  tener hardware real, no como fallas de la auditoría. Con esto se cierra la Fase 20 y el plan
  completo de la app nativa iOS (T16-T27).

---

## Checklist final — lo que le queda al USUARIO por hacer manualmente (App Store)

*El agente deja el proyecto, los assets y los textos listos y compilando. Lo siguiente REQUIERE las
credenciales del usuario y/o hardware/GUI, y NO lo puede hacer el agente (ver el "Límite importante"
del ADR nativo en ARQUITECTURA.md):*

1. **Instalar herramientas / abrir en Xcode**: abrir `ios/TelepromtCam.xcodeproj` en Xcode (26+). No
   hace falta instalar nada extra (el proyecto es un `.xcodeproj` comprometido, sin XcodeGen/Tuist).
2. **Signing & Capabilities**: seleccionar su **Team ID** de Apple Developer en el target, dejar que
   Xcode gestione el firmado automático (o configurar certificados/perfiles manuales). Crear el
   **App ID** `com.juandiegorodri.teleprompter` en el portal de Apple Developer si no existe (Xcode
   suele crearlo solo con "Automatically manage signing").
3. **Probar en simulador GUI y en iPhone real**: correr la app, ejercitar el camino feliz que este
   entorno no pudo (cámara en vivo, grabación real, guardar al carrete, control por voz con micrófono
   real — recalibrar los umbrales de T22 si hace falta, es esperable en la primera prueba).
4. **Crear la app en App Store Connect**: nombre TelepromtCam, bundle id
   `com.juandiegorodri.teleprompter`, rellenar la ficha con el texto de `ios/AppStore/metadata.md`.
5. **Screenshots reales**: capturarlos desde el simulador (tamaños que exige App Store Connect, p. ej.
   6.7"/6.9" y los que pida el formulario) — el agente NO genera screenshots de la app corriendo.
6. **Cuestionario de privacidad ("App Privacy")**: responderlo en App Store Connect usando
   `ios/AppStore/resumen-privacidad-apple.md` (esencialmente "Data Not Collected") y enlazar la
   **URL de política de privacidad** (`privacidad.html` en GitHub Pages, ya creado en T26 — confirmar
   que Pages la sirve tras el push).
7. **Archivar y subir el build**: `Product → Archive` en Xcode y subir con el Organizer o Transporter
   a App Store Connect; asignar el build a la versión 1.0.
8. **Enviar a revisión**: completar clasificación de edad, precio (gratis), y **Submit for Review**.

> **Nota para el ORQUESTADOR (no lo hace el arquitecto):** al cerrar esta fase, MAPA.md está muy
> desalineado (ya lo estaba desde T13) y NO refleja el árbol nuevo de `ios/`. Hay que actualizar
> `control/MAPA.md`: agregar una sección "Código iOS (nativo)" con las rutas de `ios/TelepromtCam/`
> (App, Camara, Voz, Teleprompter, Editor, Ajustes, Comun), `ios/TelepromtCam.xcodeproj`,
> `ios/AppStore/` y los `privacidad.html`/`soporte.html` de la raíz — la estructura canónica está en
> el sub-ADR de ARQUITECTURA.md. Editar MAPA.md queda fuera del alcance del arquitecto (solo escribe
> en TAREAS.md y ARQUITECTURA.md); el cronista/orquestador debe hacer esa pasada anti-deriva.

---

## Fase 21 — Primer feedback real de simulador: voz no detectada, espejo de video, reordenar ajustes

### ⬜ T28. Arreglar detección de voz (audio vía AVCaptureSession, no AVAudioEngine separado), espejar grabación, mover preview de ajustes arriba de tipografía

- **Alcance**:
  - INCLUYE:
    1. **Arreglar la detección de voz (bug real, confirmado por el usuario en simulador)**: el
       texto no avanza — el guion queda completamente quieto. Causa más probable: `VozController`
       (T22) usa un `AVAudioEngine` PROPIO con su propia `AVAudioSession`, compitiendo por el mismo
       micrófono que ya está siendo consumido por la `AVCaptureSession` de `CamaraController`
       (T17/T18) para la grabación de video+audio. Esta arquitectura de "dos consumidores
       independientes del mismo hardware de audio" es frágil y en el simulador (y posiblemente en
       dispositivo real) puede resultar en que el tap de `AVAudioEngine` reciba buffers en silencio
       o no reciba nada, porque `AVCaptureSession` ya reclamó la ruta de audio.
       **Solución correcta (patrón estándar de iOS para este caso exacto)**: eliminar el
       `AVAudioEngine`/`AVAudioSession` propio de `VozController` y en su lugar agregar un
       `AVCaptureAudioDataOutput` a la MISMA `AVCaptureSession` de `CamaraController` (junto al
       `AVCaptureMovieFileOutput` de T18), con su delegate (`AVCaptureAudioDataOutputSampleBufferDelegate`)
       entregando `CMSampleBuffer`s desde los que `VozController` calcula el RMS (extrayendo los
       datos PCM del `CMSampleBuffer` con `CMSampleBufferGetAudioBufferList`/`AudioBufferList`, en
       vez de `AVAudioPCMBuffer`). Esto evita por completo el conflicto de dos consumidores de audio
       — un solo output de la sesión de captura alimenta tanto la grabación (vía
       `AVCaptureMovieFileOutput`) como el análisis de voz (vía `AVCaptureAudioDataOutput`), ambos
       de la misma `AVCaptureSession`, sin pelear por la `AVAudioSession`. El resto de la lógica de
       `VozController` (histéresis, el remapeo de rango obligatorio de la lección crítica de T22,
       suavizado, enganche a `TeleprompterController.setVelocidad`) se conserva igual — solo cambia
       la FUENTE del audio, no el algoritmo de VAD.
    2. **Espejar el video grabado para que coincida con el preview**: con la cámara frontal, el
       preview normalmente se ve en espejo (como un espejo real / selfie), pero el archivo grabado
       por defecto NO queda espejado (queda "como te ven los demás"). El usuario pidió que el video
       grabado se vea igual que el preview que está viendo (espejado). En `CamaraController.swift`,
       al configurar/usar el `AVCaptureMovieFileOutput`, localizar su `AVCaptureConnection` de video
       y, cuando la cámara activa es la frontal (`.front`), poner `connection.isVideoMirrored = true`
       (verificando `connection.isVideoMirroringSupported` antes). Al cambiar a cámara trasera,
       `isVideoMirrored` debe volver a `false` (la trasera no se espeja). Aplicar esto tanto en la
       configuración inicial como dentro de `cambiarLente(a:)`.
    3. **Preview de ajustes arriba de la tipografía**: en `PantallaAjustes.swift`, mover la sección
       que contiene `PreviewAjustes` (hoy al final, después de Velocidad) para que quede
       INMEDIATAMENTE DESPUÉS de la sección "Cámara" y ANTES de la sección "Tipografía" — así el
       usuario ve el efecto en vivo mientras mueve los sliders de abajo, en vez de tener que hacer
       scroll hasta el final para verlo.
  - NO INCLUYE: cambiar el algoritmo de VAD (histéresis/remapeo/suavizado de T22 se mantienen
    intactos, solo cambia la fuente de audio), ni tocar el flujo de grabación de T24 más allá de
    agregar el espejo.
- **Archivos**: `ios/TelepromtCam/Voz/VozController.swift` (reescritura de la fuente de audio),
  `ios/TelepromtCam/Camara/CamaraController.swift` (agrega `AVCaptureAudioDataOutput` a la sesión,
  espejo de video), `ios/TelepromtCam/Ajustes/PantallaAjustes.swift` (reordenar secciones).
- **Definición de Hecho**:
  - [ ] `xcodebuild ... build` → `** BUILD SUCCEEDED **`, 0 errores, 0 warnings nuevos.
  - [ ] Revisión de código: `VozController` ya NO crea su propio `AVAudioEngine`/`AVAudioSession`;
    consume audio vía `AVCaptureAudioDataOutput` agregado a `CamaraController.session`; el cálculo
    de RMS opera sobre los datos del `CMSampleBuffer` correctamente extraídos; histéresis/remapeo/
    suavizado/enganche a `setVelocidad` se conservan sin cambios de lógica.
  - [ ] Revisión de código: `isVideoMirrored` se aplica `true` para cámara frontal y `false` para
    trasera, verificando `isVideoMirroringSupported` antes, tanto en la configuración inicial como
    en `cambiarLente(a:)`.
  - [ ] `PantallaAjustes.swift`: la sección del preview aparece antes que "Tipografía" en el orden
    del `Form` (verificable leyendo el orden de las `Section` en el código).
  - [ ] Prueba funcional (que el texto ahora sí siga la voz real, que el video grabado salga
    espejado como el preview, que el preview de ajustes se vea arriba): **la hace el usuario** —
    esta vez en simulador con micrófono/cámara del Mac (ya confirmó que el simulador SÍ tiene
    acceso a cámara/mic reales del equipo), así que a diferencia de tareas anteriores, esta SÍ es
    razonable pedir que se confirme rápido tras el próximo build.
- **Evidencia del verificador**: *(pendiente)*

---

## Bugs

*Lo que el verificador o cualquiera encuentre fuera del alcance de la tarea en curso.
Nada se arregla "de pasada": se anota aquí y se prioriza.*

| # | Bug | Detectado | Estado |
|---|---|---|---|
| 1 | Si se activa "Modo voz" (`#btn-modo-voz`) antes de activar la detección de voz (`#btn-activar-voz`), `iniciarScroll()` arranca pero el enganche de velocidad no se aplica (vive dentro del loop de detección, que aún no corre) — el scroll queda a la última velocidad conocida en vez de partir en 0. | T8 (2026-07-10) | Resuelto por T12: se elimina el botón separado de activar voz (se fusiona con activar cámara) y se quita `iniciarScroll()` de `activarModoVoz()`, con lo que este escenario deja de ser posible. |

## Ideas / futuro (fuera de v1)

- ~~Superponer texto sobre cámara, selector de lente, preview en vivo, velocidad configurable~~ —
  movido a T13 (Fase 8), el usuario confirmó que lo quiere ya, ya no es "futuro".
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
