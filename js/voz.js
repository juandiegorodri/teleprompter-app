console.log("cargado: voz");

// T7: Detección de actividad de voz (VAD por energía) con Web Audio API.
// Expone estaHablando() y nivelActual() para que T8 los use al enganchar la velocidad del teleprompter.
// NO acopla con teleprompter.js (eso es T8) ni reconoce palabras: solo mide energía de audio.

import { obtenerStream } from "./camara.js";

// --- Umbrales de histéresis (ajustables) ---
// Se comparan contra el nivel RMS normalizado (0-1). UMBRAL_ENTRAR > UMBRAL_SALIR
// para evitar parpadeo: hace falta superar el umbral alto para pasar a "habla",
// y bajar del umbral bajo para volver a "silencio".
const UMBRAL_ENTRAR_HABLA = 0.06;
const UMBRAL_SALIR_HABLA = 0.03;

let audioContext = null;
let analyser = null;
let fuenteAudio = null;
let datosTiempo = null;
let rafId = null;

let hablando = false;
let nivel = 0;

const btnActivarVoz = document.getElementById("btn-activar-voz");
const mensajeVoz = document.getElementById("mensaje-voz");
const barraNivelVoz = document.getElementById("barra-nivel-voz");
const indicadorEstadoVoz = document.getElementById("indicador-estado-voz");

export function estaHablando() {
  return hablando;
}

export function nivelActual() {
  return nivel;
}

function mostrarMensaje(texto) {
  if (!mensajeVoz) return;
  mensajeVoz.textContent = texto;
  mensajeVoz.hidden = false;
}

function ocultarMensaje() {
  if (!mensajeVoz) return;
  mensajeVoz.hidden = true;
  mensajeVoz.textContent = "";
}

function actualizarIndicadorVisual() {
  if (barraNivelVoz) {
    const porcentaje = Math.min(100, Math.round(nivel * 100));
    barraNivelVoz.style.width = `${porcentaje}%`;
  }
  if (indicadorEstadoVoz) {
    indicadorEstadoVoz.textContent = hablando ? "Hablando" : "Silencio";
    indicadorEstadoVoz.classList.toggle("hablando", hablando);
  }
}

function calcularRms(datos) {
  // getByteTimeDomainData devuelve valores 0-255 centrados en 128 (silencio = 128).
  let sumaCuadrados = 0;
  for (let i = 0; i < datos.length; i++) {
    const muestra = (datos[i] - 128) / 128; // normaliza a [-1, 1]
    sumaCuadrados += muestra * muestra;
  }
  return Math.sqrt(sumaCuadrados / datos.length); // RMS, típicamente en [0, ~0.6]
}

function loopDeteccion() {
  if (!analyser || !datosTiempo) return;

  analyser.getByteTimeDomainData(datosTiempo);
  const rms = calcularRms(datosTiempo);

  // El RMS de voz normal cae por debajo de 1.0; se usa tal cual como "nivel" 0-1 aproximado,
  // recortado por si acaso.
  nivel = Math.max(0, Math.min(1, rms));

  if (!hablando && nivel >= UMBRAL_ENTRAR_HABLA) {
    hablando = true;
  } else if (hablando && nivel < UMBRAL_SALIR_HABLA) {
    hablando = false;
  }

  actualizarIndicadorVisual();

  rafId = requestAnimationFrame(loopDeteccion);
}

async function activarDeteccionVoz() {
  ocultarMensaje();

  const stream = obtenerStream();
  if (!stream) {
    mostrarMensaje("Activa la cámara primero para poder detectar la voz.");
    return;
  }

  const pistasAudio = stream.getAudioTracks();
  if (!pistasAudio || pistasAudio.length === 0) {
    mostrarMensaje("El stream activo no tiene pista de audio disponible.");
    return;
  }

  try {
    if (!audioContext) {
      const ContextoAudio = window.AudioContext || window.webkitAudioContext;
      audioContext = new ContextoAudio();
    }

    // Requisito de gesto de usuario en iOS: resume() debe llamarse dentro del handler de click.
    await audioContext.resume();

    // Si ya había una fuente conectada (p. ej. reactivación), desconéctala antes de crear otra.
    if (fuenteAudio) {
      fuenteAudio.disconnect();
    }

    fuenteAudio = audioContext.createMediaStreamSource(stream);

    if (!analyser) {
      analyser = audioContext.createAnalyser();
      analyser.fftSize = 2048;
      datosTiempo = new Uint8Array(analyser.fftSize);
    }

    fuenteAudio.connect(analyser);
    // Nota: no se conecta analyser -> audioContext.destination para no generar eco/feedback de audio.

    if (btnActivarVoz) {
      btnActivarVoz.textContent = "Detección de voz activa";
      btnActivarVoz.disabled = true;
    }

    if (rafId === null) {
      loopDeteccion();
    }
  } catch (error) {
    console.error("Error al activar la detección de voz:", error);
    mostrarMensaje("No se pudo iniciar el análisis de audio en este navegador.");
  }
}

if (btnActivarVoz) {
  btnActivarVoz.addEventListener("click", activarDeteccionVoz);
} else {
  console.error("No se encontró el botón #btn-activar-voz");
}
