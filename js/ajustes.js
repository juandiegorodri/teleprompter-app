console.log("cargado: ajustes");

import { setVelocidadBase } from "./teleprompter.js";
import { cambiarLente } from "./camara.js";

/** Clave fija de localStorage donde se persisten los ajustes de tipografía/fondo (T9). */
const CLAVE_AJUSTES = "teleprompter:ajustes";

const RAIZ = document.documentElement;

function obtenerElementos() {
  const panel = document.getElementById("panel-ajustes");
  const botonAlternar = document.getElementById("btn-alternar-ajustes");
  const botonCerrar = document.getElementById("btn-cerrar-ajustes");
  const inputTamanoFuente = document.getElementById("input-tamano-fuente");
  const inputColorTexto = document.getElementById("input-color-texto");
  const inputOpacidadFondo = document.getElementById("input-opacidad-fondo");
  const inputProporcionCamara = document.getElementById("input-proporcion-camara");
  const inputVelocidadBase = document.getElementById("input-velocidad-base");
  const selectLenteCamara = document.getElementById("select-lente-camara");
  const previewContenedor = document.getElementById("preview-ajustes-contenedor");
  const previewTexto = document.getElementById("preview-ajustes-texto");
  return {
    panel,
    botonAlternar,
    botonCerrar,
    inputTamanoFuente,
    inputColorTexto,
    inputOpacidadFondo,
    inputProporcionCamara,
    inputVelocidadBase,
    selectLenteCamara,
    previewContenedor,
    previewTexto,
  };
}

/**
 * T13, punto 1: límites de la franja de texto superpuesta. Cambio de
 * semántica respecto a T10 — --tp-proporcion-camara ya NO es el % del 85%
 * disponible que ocupa la cámara (dos zonas apiladas), sino el % de la
 * altura TOTAL de pantalla que ocupa el bloque de texto superpuesto sobre la
 * cámara (ver comentario en :root de estilos.css). Se acota entre 15
 * (mínimo razonable para 1-2 líneas legibles) y 50 (no debe invadir el 15%
 * fijo de #zona-controles ni tapar la mayor parte del video).
 */
const PROPORCION_CAMARA_MIN = 15;
const PROPORCION_CAMARA_MAX = 50;

function acotarProporcionCamara(valor) {
  if (Number.isNaN(valor)) return 30;
  return Math.min(PROPORCION_CAMARA_MAX, Math.max(PROPORCION_CAMARA_MIN, valor));
}

/** T13, punto 3: límites del slider de velocidad base (px/s). 24 = valor original. */
const VELOCIDAD_BASE_MIN = 12;
const VELOCIDAD_BASE_MAX = 100;

function acotarVelocidadBase(valor) {
  if (Number.isNaN(valor)) return 24;
  return Math.min(VELOCIDAD_BASE_MAX, Math.max(VELOCIDAD_BASE_MIN, valor));
}

function leerVariableCss(nombre) {
  return getComputedStyle(RAIZ).getPropertyValue(nombre).trim();
}

/** Valores actuales tomados de las variables CSS ya definidas en estilos.css. */
function obtenerAjustesPorDefecto() {
  const tamanoFuenteRem = parseFloat(leerVariableCss("--tp-font-size")) || 1.15;
  const colorTexto = leerVariableCss("--tp-color-texto") || "#ffffff";
  const opacidadFondo = parseFloat(leerVariableCss("--tp-opacidad-fondo"));
  const proporcionCamara = parseFloat(leerVariableCss("--tp-proporcion-camara"));
  return {
    tamanoFuenteRem,
    colorTexto: colorAHex(colorTexto),
    opacidadFondo: Number.isNaN(opacidadFondo) ? 0.55 : opacidadFondo,
    proporcionCamara: acotarProporcionCamara(proporcionCamara),
    // T13, punto 3: velocidad base por defecto = 24 (el mismo valor original
    // de la antigua constante VELOCIDAD_BASE_PX_S en teleprompter.js).
    velocidadBase: 24,
    // T13, punto 4: lente por defecto = frontal, igual que el facingMode
    // fijo que usaba camara.js antes de esta tarea.
    lenteCamara: "user",
  };
}

/** input[type=color] solo acepta hex; si la variable venía en otro formato, se normaliza. */
function colorAHex(color) {
  if (/^#[0-9a-fA-F]{6}$/.test(color)) return color;
  const contenedorTemporal = document.createElement("div");
  contenedorTemporal.style.color = color;
  document.body.appendChild(contenedorTemporal);
  const rgb = getComputedStyle(contenedorTemporal).color;
  document.body.removeChild(contenedorTemporal);
  const coincidencia = rgb.match(/\d+/g);
  if (!coincidencia) return "#ffffff";
  const [r, g, b] = coincidencia.map(Number);
  return (
    "#" +
    [r, g, b]
      .map((valor) => valor.toString(16).padStart(2, "0"))
      .join("")
  );
}

function cargarAjustesGuardados() {
  try {
    const crudo = localStorage.getItem(CLAVE_AJUSTES);
    if (!crudo) return null;
    const datos = JSON.parse(crudo);
    if (
      typeof datos === "object" &&
      datos !== null &&
      typeof datos.tamanoFuenteRem === "number" &&
      typeof datos.colorTexto === "string" &&
      typeof datos.opacidadFondo === "number"
    ) {
      return {
        ...datos,
        proporcionCamara: acotarProporcionCamara(
          typeof datos.proporcionCamara === "number" ? datos.proporcionCamara : 30
        ),
        velocidadBase: acotarVelocidadBase(
          typeof datos.velocidadBase === "number" ? datos.velocidadBase : 24
        ),
        lenteCamara:
          datos.lenteCamara === "environment" || datos.lenteCamara === "user"
            ? datos.lenteCamara
            : "user",
      };
    }
    return null;
  } catch (error) {
    console.warn("ajustes: no se pudo leer localStorage", error);
    return null;
  }
}

function guardarAjustes(ajustes) {
  try {
    localStorage.setItem(CLAVE_AJUSTES, JSON.stringify(ajustes));
  } catch (error) {
    console.warn("ajustes: no se pudo escribir en localStorage", error);
  }
}

function aplicarAjustes(ajustes) {
  RAIZ.style.setProperty("--tp-font-size", `${ajustes.tamanoFuenteRem}rem`);
  RAIZ.style.setProperty("--tp-color-texto", ajustes.colorTexto);
  RAIZ.style.setProperty("--tp-opacidad-fondo", String(ajustes.opacidadFondo));
  RAIZ.style.setProperty(
    "--tp-proporcion-camara",
    String(acotarProporcionCamara(ajustes.proporcionCamara))
  );
  // T13, punto 3: aplica también la velocidad base al teleprompter real.
  setVelocidadBase(acotarVelocidadBase(ajustes.velocidadBase));
}

function sincronizarControles(elementos, ajustes) {
  const {
    inputTamanoFuente,
    inputColorTexto,
    inputOpacidadFondo,
    inputProporcionCamara,
    inputVelocidadBase,
    selectLenteCamara,
  } = elementos;
  if (inputTamanoFuente) inputTamanoFuente.value = String(ajustes.tamanoFuenteRem);
  if (inputColorTexto) inputColorTexto.value = ajustes.colorTexto;
  if (inputOpacidadFondo) inputOpacidadFondo.value = String(ajustes.opacidadFondo);
  if (inputProporcionCamara) inputProporcionCamara.value = String(ajustes.proporcionCamara);
  if (inputVelocidadBase) inputVelocidadBase.value = String(ajustes.velocidadBase);
  if (selectLenteCamara) selectLenteCamara.value = ajustes.lenteCamara;
}

function mostrarPanel(panel) {
  if (!panel) return;
  panel.hidden = false;
}

function ocultarPanel(panel) {
  if (!panel) return;
  panel.hidden = true;
}

function alternarPanel(panel) {
  if (!panel) return;
  if (panel.hidden) {
    mostrarPanel(panel);
  } else {
    ocultarPanel(panel);
  }
}

// --- T13, punto 2: preview en vivo, aislado del teleprompter real ---------
// Ciclo de scroll propio (su propio rAF) dentro de #preview-ajustes-texto,
// que usa la velocidad base configurada (sin factor de voz: aquí no hay
// nadie hablando, es solo para calibrar visualmente). No importa nada de
// teleprompter.js para no compartir estado con una grabación en curso.
let previewAnimando = false;
let previewIdAnimacion = null;
let previewUltimoTimestamp = null;
let previewPosicionPx = 0;
let previewVelocidadPxS = 24;

function previewObtenerElementos() {
  const contenedor = document.getElementById("preview-ajustes-contenedor");
  const texto = document.getElementById("preview-ajustes-texto");
  return { contenedor, texto };
}

function previewPaso(timestampActual) {
  if (!previewAnimando) return;
  const { contenedor, texto } = previewObtenerElementos();
  if (!contenedor || !texto) {
    previewAnimando = false;
    return;
  }

  if (previewUltimoTimestamp === null) {
    previewUltimoTimestamp = timestampActual;
  }
  const deltaSegundos = (timestampActual - previewUltimoTimestamp) / 1000;
  previewUltimoTimestamp = timestampActual;

  const maximo = Math.max(0, texto.scrollHeight - contenedor.clientHeight);
  previewPosicionPx += previewVelocidadPxS * deltaSegundos;

  if (previewPosicionPx >= maximo) {
    // T13, punto 2: ciclo propio de reinicio cuando termina, para poder
    // calibrar en bucle sin intervención manual.
    previewPosicionPx = 0;
    previewUltimoTimestamp = null;
  }

  texto.style.transform = `translateY(-${previewPosicionPx}px)`;
  previewIdAnimacion = requestAnimationFrame(previewPaso);
}

function previewIniciar() {
  if (previewAnimando) return;
  previewAnimando = true;
  previewUltimoTimestamp = null;
  previewIdAnimacion = requestAnimationFrame(previewPaso);
}

function previewDetener() {
  previewAnimando = false;
  if (previewIdAnimacion !== null) {
    cancelAnimationFrame(previewIdAnimacion);
    previewIdAnimacion = null;
  }
  previewUltimoTimestamp = null;
}

function previewSetVelocidad(pxPorSegundo) {
  previewVelocidadPxS = Number(pxPorSegundo) || 24;
}

function inicializarAjustes() {
  const elementos = obtenerElementos();
  const {
    panel,
    botonAlternar,
    botonCerrar,
    inputTamanoFuente,
    inputColorTexto,
    inputOpacidadFondo,
    inputProporcionCamara,
    inputVelocidadBase,
    selectLenteCamara,
  } = elementos;

  if (!panel) {
    console.warn("ajustes: no se encontró #panel-ajustes en el DOM");
    return;
  }

  // Ajustes iniciales: los guardados en localStorage si existen, si no los
  // valores actuales definidos en :root de estilos.css (se aplican antes de
  // que el usuario interactúe con los controles).
  const ajustesGuardados = cargarAjustesGuardados();
  const ajustesIniciales = ajustesGuardados ?? obtenerAjustesPorDefecto();

  aplicarAjustes(ajustesIniciales);
  sincronizarControles(elementos, ajustesIniciales);
  previewSetVelocidad(ajustesIniciales.velocidadBase);
  if (!ajustesGuardados) {
    guardarAjustes(ajustesIniciales);
  }

  if (botonAlternar) {
    botonAlternar.addEventListener("click", () => {
      alternarPanel(panel);
      // El preview solo corre mientras el panel está abierto, para no
      // desperdiciar un rAF en segundo plano.
      if (!panel.hidden) {
        previewIniciar();
      } else {
        previewDetener();
      }
    });
  } else {
    console.warn("ajustes: no se encontró #btn-alternar-ajustes en el DOM");
  }

  if (botonCerrar) {
    botonCerrar.addEventListener("click", () => {
      ocultarPanel(panel);
      previewDetener();
    });
  } else {
    console.warn("ajustes: no se encontró #btn-cerrar-ajustes en el DOM");
  }

  function actualizarYGuardar() {
    const ajustes = {
      tamanoFuenteRem: inputTamanoFuente
        ? parseFloat(inputTamanoFuente.value)
        : ajustesIniciales.tamanoFuenteRem,
      colorTexto: inputColorTexto ? inputColorTexto.value : ajustesIniciales.colorTexto,
      opacidadFondo: inputOpacidadFondo
        ? parseFloat(inputOpacidadFondo.value)
        : ajustesIniciales.opacidadFondo,
      proporcionCamara: acotarProporcionCamara(
        inputProporcionCamara
          ? parseFloat(inputProporcionCamara.value)
          : ajustesIniciales.proporcionCamara
      ),
      velocidadBase: acotarVelocidadBase(
        inputVelocidadBase
          ? parseFloat(inputVelocidadBase.value)
          : ajustesIniciales.velocidadBase
      ),
      lenteCamara: selectLenteCamara ? selectLenteCamara.value : ajustesIniciales.lenteCamara,
    };
    aplicarAjustes(ajustes);
    previewSetVelocidad(ajustes.velocidadBase);
    guardarAjustes(ajustes);
  }

  if (inputTamanoFuente) {
    inputTamanoFuente.addEventListener("input", actualizarYGuardar);
  } else {
    console.warn("ajustes: no se encontró #input-tamano-fuente en el DOM");
  }

  if (inputColorTexto) {
    inputColorTexto.addEventListener("input", actualizarYGuardar);
  } else {
    console.warn("ajustes: no se encontró #input-color-texto en el DOM");
  }

  if (inputOpacidadFondo) {
    inputOpacidadFondo.addEventListener("input", actualizarYGuardar);
  } else {
    console.warn("ajustes: no se encontró #input-opacidad-fondo en el DOM");
  }

  if (inputProporcionCamara) {
    inputProporcionCamara.addEventListener("input", actualizarYGuardar);
  } else {
    console.warn("ajustes: no se encontró #input-proporcion-camara en el DOM");
  }

  if (inputVelocidadBase) {
    inputVelocidadBase.addEventListener("input", actualizarYGuardar);
  } else {
    console.warn("ajustes: no se encontró #input-velocidad-base en el DOM");
  }

  // T13, punto 4: selector de cámara/lente. Al cambiar, persiste la
  // preferencia y pide a camara.js que cambie el stream activo en vivo (si
  // ya hay uno). Si falla, camara.js se encarga de mostrar el mensaje y
  // mantener el stream anterior — aquí solo revertimos el <select> visual.
  if (selectLenteCamara) {
    selectLenteCamara.addEventListener("change", async () => {
      const lenteElegida = selectLenteCamara.value;
      const exito = await cambiarLente(lenteElegida);
      if (!exito) {
        // Revierte el control a la lente que sigue realmente activa.
        const ajustesActuales = cargarAjustesGuardados() ?? ajustesIniciales;
        selectLenteCamara.value = ajustesActuales.lenteCamara;
        return;
      }
      actualizarYGuardar();
    });
  } else {
    console.warn("ajustes: no se encontró #select-lente-camara en el DOM");
  }
}

inicializarAjustes();
