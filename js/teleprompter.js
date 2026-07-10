console.log("cargado: teleprompter");

const GUION_EJEMPLO = `Bienvenidos a este teleprompter de ejemplo. Este es el primer párrafo de un guion pensado para probar que el bloque de texto sea claramente más alto que la pantalla disponible, de modo que exista contenido suficiente para desplazar en las fases siguientes del proyecto.

El objetivo de esta pantalla es mostrar el texto con buena legibilidad sobre la imagen en vivo de la cámara, usando un fondo translúcido que no tape del todo el video mientras mantiene un contraste alto para la tipografía.

Más adelante, en la siguiente fase, este mismo bloque de texto se desplazará automáticamente hacia arriba a una velocidad constante, controlada por un temporizador basado en el tiempo transcurrido y no en el número de cuadros por segundo.

Después de eso, un editor permitirá reemplazar este guion de ejemplo por el texto real que el usuario quiera leer, guardándolo en el almacenamiento local del navegador para que persista entre sesiones.

Finalmente, un módulo de detección de voz permitirá controlar la velocidad de desplazamiento según el ritmo real de quien está hablando frente a la cámara, deteniendo el avance en los silencios y acelerándolo cuando la persona habla más rápido.

Este párrafo final existe únicamente para asegurar que el contenido total del guion supere ampliamente la altura visible de la zona de texto en cualquier pantalla de teléfono, confirmando así que el contenedor interno necesita desplazamiento vertical para mostrarse completo.`;

/**
 * Monta un guion dentro del contenedor interno del teleprompter (#teleprompter-texto).
 * Reemplaza cualquier contenido previo. Reusable por el editor (T6) para inyectar
 * el texto escrito/persistido por el usuario.
 * @param {string} texto - Guion a mostrar. Los saltos de línea dobles se tratan como párrafos.
 */
export function montarTexto(texto) {
  const contenedorTexto = document.getElementById("teleprompter-texto");
  if (!contenedorTexto) {
    console.warn("teleprompter: no se encontró #teleprompter-texto en el DOM");
    return;
  }

  contenedorTexto.innerHTML = "";

  const parrafos = String(texto)
    .split(/\n\s*\n/)
    .map((p) => p.trim())
    .filter((p) => p.length > 0);

  for (const parrafo of parrafos) {
    const elementoParrafo = document.createElement("p");
    elementoParrafo.textContent = parrafo;
    contenedorTexto.appendChild(elementoParrafo);
  }

  // Al montar un texto nuevo, el scroll vuelve a foja cero.
  reiniciarScroll();
}

// --- Scroll automático (T5) --------------------------------------------

/** Velocidad base en píxeles por segundo. Multiplicada por el factor de setVelocidad(). */
const VELOCIDAD_BASE_PX_S = 40;

let factorVelocidad = 1;
let posicionActualPx = 0;
let animando = false;
let idAnimacion = null;
let ultimoTimestamp = null;

/**
 * Cambia el factor de velocidad en vivo (1 = velocidad base). Pensado para que
 * voz.js (T8) lo controle según el ritmo de habla detectado.
 * @param {number} factor - Multiplicador de la velocidad base. Debe ser >= 0.
 */
export function setVelocidad(factor) {
  const valor = Number(factor);
  if (!Number.isFinite(valor) || valor < 0) {
    console.warn("teleprompter: setVelocidad recibió un valor inválido", factor);
    return;
  }
  factorVelocidad = valor;
}

function obtenerElementos() {
  const contenedor = document.getElementById("teleprompter-contenedor");
  const texto = document.getElementById("teleprompter-texto");
  return { contenedor, texto };
}

function aplicarPosicion() {
  const { texto } = obtenerElementos();
  if (!texto) return;
  texto.style.transform = `translateY(-${posicionActualPx}px)`;
}

function desplazamientoMaximoPx() {
  const { contenedor, texto } = obtenerElementos();
  if (!contenedor || !texto) return 0;
  return Math.max(0, texto.scrollHeight - contenedor.clientHeight);
}

function paso(timestampActual) {
  if (!animando) return;

  if (ultimoTimestamp === null) {
    ultimoTimestamp = timestampActual;
  }
  const deltaSegundos = (timestampActual - ultimoTimestamp) / 1000;
  ultimoTimestamp = timestampActual;

  const maximo = desplazamientoMaximoPx();
  posicionActualPx += VELOCIDAD_BASE_PX_S * factorVelocidad * deltaSegundos;

  if (posicionActualPx >= maximo) {
    posicionActualPx = maximo;
    aplicarPosicion();
    pausarScroll();
    return;
  }

  aplicarPosicion();
  idAnimacion = requestAnimationFrame(paso);
}

/** Arranca (o reanuda) el scroll automático desde la posición actual. */
export function iniciarScroll() {
  if (animando) return;
  animando = true;
  ultimoTimestamp = null;
  idAnimacion = requestAnimationFrame(paso);
}

/** Pausa el scroll automático, dejando el texto detenido en su posición actual. */
export function pausarScroll() {
  animando = false;
  if (idAnimacion !== null) {
    cancelAnimationFrame(idAnimacion);
    idAnimacion = null;
  }
  ultimoTimestamp = null;
}

/** Alterna entre iniciar y pausar el scroll. */
export function alternarScroll() {
  if (animando) {
    pausarScroll();
  } else {
    iniciarScroll();
  }
}

/** Reinicia el texto a su posición inicial (arriba del todo) y pausa el scroll. */
export function reiniciarScroll() {
  pausarScroll();
  posicionActualPx = 0;
  aplicarPosicion();
}

function actualizarEtiquetaBoton() {
  const boton = document.getElementById("btn-play-pausa");
  if (!boton) return;
  boton.textContent = animando ? "Pausa" : "Play";
}

function inicializarControles() {
  const botonPlayPausa = document.getElementById("btn-play-pausa");
  const botonReiniciar = document.getElementById("btn-reiniciar");

  if (botonPlayPausa) {
    botonPlayPausa.addEventListener("click", () => {
      alternarScroll();
      actualizarEtiquetaBoton();
    });
  } else {
    console.warn("teleprompter: no se encontró #btn-play-pausa en el DOM");
  }

  if (botonReiniciar) {
    botonReiniciar.addEventListener("click", () => {
      reiniciarScroll();
      actualizarEtiquetaBoton();
    });
  } else {
    console.warn("teleprompter: no se encontró #btn-reiniciar en el DOM");
  }
}

montarTexto(GUION_EJEMPLO);
inicializarControles();
