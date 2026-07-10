console.log("cargado: camara");

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
    if (btnGrabar) {
      btnGrabar.disabled = false;
    }
  } catch (error) {
    console.error("Error al acceder a la cámara/micrófono:", error);
    let texto = "No se pudo acceder a la cámara. Revisa los permisos e inténtalo de nuevo.";
    if (error && (error.name === "NotAllowedError" || error.name === "PermissionDeniedError")) {
      texto = "Permiso de cámara/micrófono denegado. Actívalo en Ajustes para usar el teleprompter.";
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
  });

  mediaRecorder.addEventListener("error", (evento) => {
    console.error("Error de MediaRecorder:", evento.error);
    mostrarMensaje("Ocurrió un error durante la grabación.");
    grabando = false;
    actualizarUiGrabacion();
  });

  mediaRecorder.start();
  grabando = true;
  actualizarUiGrabacion();
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
