console.log("cargado: camara");

// T12: flujo simplificado — activar cámara habilita TODO en un solo gesto de
// usuario (getUserMedia). Se importa inicializarAudioContext() de voz.js para
// crear el AudioContext/AnalyserNode aquí mismo (el mismo gesto de click es
// obligatorio en iOS para poder resumir el AudioContext) e iniciarScroll/
// pausarScroll de teleprompter.js para que grabar controle el desplazamiento.
import { inicializarAudioContext } from "./voz.js";
import { iniciarScroll, pausarScroll } from "./teleprompter.js";

// Referencia al MediaStream activo, accesible para otros módulos (grabación en T3, análisis de audio en Fase 4).
let streamActual = null;

export function obtenerStream() {
  return streamActual;
}

// También expuesto en window para inspección manual desde consola (p. ej. en verificación con Safari iOS).
window.__appStream = null;

const btnActivarCamara = document.getElementById("btn-activar-camara");
const videoCamara = document.getElementById("video-camara");
const mensajeCamara = document.getElementById("mensaje-camara");
const btnGrabar = document.getElementById("btn-grabar");
const indicadorGrabando = document.getElementById("indicador-grabando");
const videoResultado = document.getElementById("video-resultado");
const enlaceDescarga = document.getElementById("enlace-descarga");
const btnAlternarConfig = document.getElementById("btn-alternar-config");
// T12: todos los controles secundarios (agrupados en #panel-config) arrancan
// disabled en el HTML y se habilitan aquí, una vez que getUserMedia resuelve.
const IDS_CONTROLES_SECUNDARIOS = [
  "btn-alternar-config",
  "btn-modo-voz",
  "btn-play-pausa",
  "btn-reiniciar",
  "btn-alternar-editor",
  "btn-alternar-ajustes",
];

let mediaRecorder = null;
let chunksGrabacion = [];
let grabando = false;
let mimeTypeElegido = "";
let urlObjetoAnterior = null;

const CANDIDATOS_MIME = [
  "video/mp4",
  "video/webm;codecs=vp9,opus",
  "video/webm;codecs=vp8,opus",
  "video/webm",
];

function elegirMimeType() {
  if (typeof MediaRecorder === "undefined" || !MediaRecorder.isTypeSupported) {
    return "";
  }
  for (const candidato of CANDIDATOS_MIME) {
    if (MediaRecorder.isTypeSupported(candidato)) {
      return candidato;
    }
  }
  return "";
}

function mostrarMensaje(texto) {
  if (!mensajeCamara) return;
  mensajeCamara.textContent = texto;
  mensajeCamara.hidden = false;
}

function ocultarMensaje() {
  if (!mensajeCamara) return;
  mensajeCamara.hidden = true;
  mensajeCamara.textContent = "";
}

async function activarCamara() {
  ocultarMensaje();

  // getUserMedia solo existe en "contexto seguro" (HTTPS o localhost). Sobre
  // http://<ip-local> en Safari iOS, navigator.mediaDevices es undefined y el
  // error real queda oculto detrás de un TypeError genérico si no se detecta antes.
  if (!window.isSecureContext || !navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
    mostrarMensaje(
      "Esta página no se está sirviendo por HTTPS (ni es localhost), así que Safari no permite " +
      "usar la cámara aquí — esto no es un permiso que puedas activar desde Ajustes. Abre la app " +
      "desde una URL https:// (por ejemplo un túnel HTTPS) e inténtalo de nuevo."
    );
    return;
  }

  try {
    const stream = await navigator.mediaDevices.getUserMedia({
      video: { facingMode: "user" },
      audio: true,
    });
    streamActual = stream;
    window.__appStream = stream;
    if (videoCamara) {
      videoCamara.srcObject = stream;
    }

    // T12, punto 1: el botón "Activar cámara" se oculta y aparece "Grabar" en
    // su lugar (mismo gesto de usuario, ahora dedicado a grabar/detener).
    if (btnActivarCamara) {
      btnActivarCamara.hidden = true;
    }
    if (btnGrabar) {
      btnGrabar.hidden = false;
      btnGrabar.disabled = false;
    }

    // T12, punto 2: habilita todos los controles secundarios ahora que la
    // cámara (y el micrófono) están disponibles.
    for (const id of IDS_CONTROLES_SECUNDARIOS) {
      const boton = document.getElementById(id);
      if (boton) boton.disabled = false;
    }

    // T12, punto 3: mismo gesto de usuario -> inicializa aquí el AudioContext/
    // AnalyserNode de detección de voz (ya no existe #btn-activar-voz).
    inicializarAudioContext(stream);
  } catch (error) {
    console.error("Error al acceder a la cámara/micrófono:", error);
    let texto = "No se pudo acceder a la cámara. Revisa los permisos e inténtalo de nuevo.";
    if (error && (error.name === "NotAllowedError" || error.name === "PermissionDeniedError")) {
      texto = "Permiso de cámara/micrófono denegado. Actívalo en Ajustes → Safari (o Ajustes de " +
        "esta app) para usar el teleprompter.";
    } else if (error && error.name === "NotFoundError") {
      texto = "No se encontró ninguna cámara disponible en este dispositivo.";
    }
    mostrarMensaje(texto);
  }
}

function iniciarGrabacion() {
  if (!streamActual) {
    mostrarMensaje("Activa la cámara antes de grabar.");
    return;
  }

  chunksGrabacion = [];
  mimeTypeElegido = elegirMimeType();

  const opciones = mimeTypeElegido ? { mimeType: mimeTypeElegido } : undefined;

  try {
    mediaRecorder = opciones ? new MediaRecorder(streamActual, opciones) : new MediaRecorder(streamActual);
  } catch (error) {
    console.error("No se pudo crear MediaRecorder:", error);
    mostrarMensaje("Este navegador no permite grabar video en este formato.");
    return;
  }

  console.log("MediaRecorder usando mimeType:", mediaRecorder.mimeType || mimeTypeElegido || "(por defecto del navegador)");

  mediaRecorder.addEventListener("dataavailable", (evento) => {
    if (evento.data && evento.data.size > 0) {
      chunksGrabacion.push(evento.data);
    }
  });

  mediaRecorder.addEventListener("stop", () => {
    const tipoBlob = mediaRecorder.mimeType || mimeTypeElegido || "video/webm";
    const blob = new Blob(chunksGrabacion, { type: tipoBlob });
    const url = URL.createObjectURL(blob);

    if (urlObjetoAnterior) {
      URL.revokeObjectURL(urlObjetoAnterior);
    }
    urlObjetoAnterior = url;

    if (videoResultado) {
      videoResultado.src = url;
      videoResultado.hidden = false;
    }
    if (enlaceDescarga) {
      enlaceDescarga.href = url;
      const extension = tipoBlob.includes("mp4") ? "mp4" : "webm";
      enlaceDescarga.download = `grabacion.${extension}`;
      enlaceDescarga.hidden = false;
    }

    grabando = false;
    actualizarUiGrabacion();
    chunksGrabacion = [];

    // T12, punto 5: al detener la grabación se pausa el scroll del teleprompter.
    pausarScroll();
  });

  mediaRecorder.addEventListener("error", (evento) => {
    console.error("Error de MediaRecorder:", evento.error);
    mostrarMensaje("Ocurrió un error durante la grabación.");
    grabando = false;
    actualizarUiGrabacion();
    pausarScroll();
  });

  mediaRecorder.start();
  grabando = true;
  actualizarUiGrabacion();

  // T12, punto 5: grabar controla el teleprompter — arranca el scroll junto
  // con la grabación.
  iniciarScroll();
}

function detenerGrabacion() {
  if (mediaRecorder && mediaRecorder.state !== "inactive") {
    mediaRecorder.stop();
  }
}

function actualizarUiGrabacion() {
  if (btnGrabar) {
    btnGrabar.textContent = grabando ? "Detener" : "Grabar";
  }
  if (indicadorGrabando) {
    indicadorGrabando.hidden = !grabando;
  }
}

function alternarGrabacion() {
  if (grabando) {
    detenerGrabacion();
  } else {
    iniciarGrabacion();
  }
}

if (btnActivarCamara) {
  btnActivarCamara.addEventListener("click", activarCamara);
} else {
  console.error("No se encontró el botón #btn-activar-camara");
}

if (btnGrabar) {
  btnGrabar.addEventListener("click", alternarGrabacion);
} else {
  console.error("No se encontró el botón #btn-grabar");
}

// T12, punto 6: agrupa Modo voz/Play-Pausa/Reiniciar/Editar guion/Ajustes en un
// panel secundario oculto por defecto, reusando el patrón de panel de T6/T9.
const panelConfig = document.getElementById("panel-config");

function alternarPanelConfig() {
  if (!panelConfig) return;
  panelConfig.hidden = !panelConfig.hidden;
}

if (btnAlternarConfig) {
  btnAlternarConfig.addEventListener("click", alternarPanelConfig);
} else {
  console.error("No se encontró el botón #btn-alternar-config");
}
