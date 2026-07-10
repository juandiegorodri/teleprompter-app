console.log("cargado: voz");

// T7: Detección de actividad de voz (VAD por energía) con Web Audio API.
// Expone estaHablando() y nivelActual() para que T8 los use al enganchar la velocidad del teleprompter.
// NO acopla con teleprompter.js (eso es T8) ni reconoce palabras: solo mide energía de audio.

import { setVelocidad } from "./teleprompter.js";

// --- Umbrales de histéresis (ajustables) ---
// Se comparan contra el nivel RMS normalizado (0-1). UMBRAL_ENTRAR > UMBRAL_SALIR
// para evitar parpadeo: hace falta superar el umbral alto para pasar a "habla",
// y bajar del umbral bajo para volver a "silencio".
//
// T14, punto 1 — SEGUNDA CALIBRACIÓN A CIEGAS (sin micrófono real disponible en
// este entorno de desarrollo): el usuario probó en su iPhone real tras T12/T13
// y reportó que el avance "está muy lento y no sigue la velocidad al hablar".
// Eso es consistente con que el RMS típico que produce el micrófono de un
// iPhone en habla normal (a distancia de teleprompter, no pegado a la boca)
// cae muy por debajo de los umbrales anteriores (0.06/0.03) — el estado casi
// nunca cruzaba a "hablando", así que aplicarEngancheVelocidad() quedaba casi
// siempre calculando sobre factorObjetivo = 0. Se bajan ambos umbrales a un
// orden de magnitud menor (aprox. una décima parte) para que el habla normal
// los cruce de forma confiable. Como sigue siendo una estimación sin poder
// verificarla con audio real, es posible que haga falta un TERCER ajuste tras
// esta ronda de prueba (en cualquier dirección: más bajo si sigue sin
// reaccionar, o más alto si ahora dispara con ruido ambiente).
const UMBRAL_ENTRAR_HABLA = 0.015;
const UMBRAL_SALIR_HABLA = 0.008;

// --- T8: Enganche voz -> velocidad del teleprompter ---
// Se implementa aquí (en voz.js, importando de teleprompter.js) porque voz.js ya
// contiene el loop de análisis de audio (requestAnimationFrame) y el estado de
// habla/nivel: reusar ese mismo loop para calcular y aplicar el factor de velocidad
// evita un segundo rAF/setInterval redundante y mantiene toda la lógica de "modo voz"
// en un solo lugar. teleprompter.js no necesita saber nada de voz.js (bajo acoplamiento).

// Rango del factor de velocidad cuando se está hablando (1 = velocidad base de T5).
// T12, punto 7: rango reducido (antes 0.5-2.5) para que el avance por voz sea
// más lento y legible por defecto, ahora que el modo voz está activo desde
// el arranque (ya no hace falta que el usuario lo active a mano).
// T14, punto 1: además de bajar los umbrales de entrada a "hablando", se sube
// el piso del factor de 0.4 a 0.7 — con los umbrales antiguos, el nivel RMS
// justo al cruzar el umbral era muy bajo y el avance resultante (con el piso
// viejo) era casi imperceptible. Con el piso más alto, incluso al borde de
// "hablando" el avance ya es claramente visible, no casi nulo. Misma nota de
// calibración a ciegas que arriba: puede necesitar un tercer ajuste.
const FACTOR_MINIMO_HABLANDO = 0.7;
const FACTOR_MAXIMO_HABLANDO = 1.8;
// Peso de la interpolación exponencial por paso (0-1): más alto = reacciona más rápido
// pero con más saltos; más bajo = más suave pero más lento para responder.
const SUAVIZADO = 0.15;

// T12, punto 3: el modo voz arranca activado por defecto — ya no requiere que
// el usuario lo active a mano (el toggle en el panel de configuración solo
// permite desactivarlo/reactivarlo).
let modoVozActivo = true;
let factorSuavizado = 0;

let audioContext = null;
let analyser = null;
let fuenteAudio = null;
let datosTiempo = null;
let rafId = null;

let hablando = false;
let nivel = 0;

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
  aplicarEngancheVelocidad();

  rafId = requestAnimationFrame(loopDeteccion);
}

// T14 (corrección post-calibración): el RMS real de un micrófono de iPhone en
// habla normal cae en un rango pequeño (aprox. UMBRAL_ENTRAR_HABLA..~0.15),
// NO en [0,1]. Multiplicar `nivel` tal cual contra (MAX-MIN) hacía que casi
// toda la variación se perdiera — el factor quedaba pegado cerca del mínimo
// sin importar qué tan fuerte/rápido hablara el usuario (bug reportado como
// "no sigue la velocidad al hablar"). NIVEL_HABLA_MAX_ESPERADO es el techo
// aproximado de RMS para una voz fuerte/rápida — todo lo que iguale o supere
// ese valor mapea al factor máximo. Sigue siendo una estimación a ciegas sin
// micrófono real disponible; puede necesitar un ajuste más.
const NIVEL_HABLA_MAX_ESPERADO = 0.15;

function remapearNivelAFraccion(nivelCrudo) {
  const rango = NIVEL_HABLA_MAX_ESPERADO - UMBRAL_ENTRAR_HABLA;
  if (rango <= 0) return 1;
  const fraccion = (nivelCrudo - UMBRAL_ENTRAR_HABLA) / rango;
  return Math.max(0, Math.min(1, fraccion));
}

/**
 * Calcula el factor de velocidad objetivo a partir de estaHablando()/nivelActual(),
 * lo suaviza con interpolación exponencial y lo aplica vía setVelocidad() de
 * teleprompter.js. Solo actúa si el modo voz está activo (modoVozActivo).
 */
function aplicarEngancheVelocidad() {
  if (!modoVozActivo) return;

  const factorObjetivo = hablando
    ? FACTOR_MINIMO_HABLANDO +
      remapearNivelAFraccion(nivel) * (FACTOR_MAXIMO_HABLANDO - FACTOR_MINIMO_HABLANDO)
    : 0;

  factorSuavizado += (factorObjetivo - factorSuavizado) * SUAVIZADO;

  // Recorte defensivo: nunca por debajo de 0 ni por encima del máximo, incluso
  // durante el transitorio del suavizado.
  const factorFinal = Math.max(0, Math.min(FACTOR_MAXIMO_HABLANDO, factorSuavizado));

  setVelocidad(factorFinal);
}

/**
 * T12, punto 3: inicializa el AudioContext/AnalyserNode de detección de voz.
 * Se exporta para que camara.js la llame dentro del mismo handler de click de
 * "Activar cámara", justo después de obtener el stream con éxito — sigue
 * siendo el mismo gesto de usuario que requiere iOS para poder resumir el
 * AudioContext, así que ya no hace falta un botón #btn-activar-voz aparte.
 * @param {MediaStream} stream - El stream ya obtenido por getUserMedia en camara.js.
 */
export async function inicializarAudioContext(stream) {
  ocultarMensaje();

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

    if (rafId === null) {
      loopDeteccion();
    }
  } catch (error) {
    console.error("Error al activar la detección de voz:", error);
    mostrarMensaje("No se pudo iniciar el análisis de audio en este navegador.");
  }
}

// --- Toggle "Modo voz" (T8, ajustado en T12) ---
// ON (valor por defecto desde T12): el enganche de voz controla la velocidad
// mientras el scroll esté corriendo (arrancado/pausado ahora por Grabar/Detener
// en camara.js, o manualmente por Play/Pausa/Reiniciar de T5).
// OFF: se detiene el enganche (deja de llamar a setVelocidad); el scroll queda
// bajo control manual normal.
// T12, punto 4: este toggle SOLO cambia modoVozActivo — nunca arranca ni para
// el scroll (eso ahora lo controla exclusivamente Grabar/Detener en camara.js,
// o Play/Pausa/Reiniciar manualmente).
const btnModoVoz = document.getElementById("btn-modo-voz");

function actualizarEtiquetaModoVoz() {
  if (!btnModoVoz) return;
  btnModoVoz.textContent = modoVozActivo ? "Modo voz: ON" : "Modo voz: OFF";
  btnModoVoz.setAttribute("aria-pressed", String(modoVozActivo));
}

function activarModoVoz() {
  modoVozActivo = true;
  factorSuavizado = 0;
  actualizarEtiquetaModoVoz();
}

function desactivarModoVoz() {
  modoVozActivo = false;
  actualizarEtiquetaModoVoz();
}

if (btnModoVoz) {
  btnModoVoz.addEventListener("click", () => {
    if (modoVozActivo) {
      desactivarModoVoz();
    } else {
      activarModoVoz();
    }
  });
} else {
  console.warn("voz: no se encontró el botón #btn-modo-voz");
}
