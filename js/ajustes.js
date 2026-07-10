console.log("cargado: ajustes");

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
  return {
    panel,
    botonAlternar,
    botonCerrar,
    inputTamanoFuente,
    inputColorTexto,
    inputOpacidadFondo,
  };
}

function leerVariableCss(nombre) {
  return getComputedStyle(RAIZ).getPropertyValue(nombre).trim();
}

/** Valores actuales tomados de las variables CSS ya definidas en estilos.css. */
function obtenerAjustesPorDefecto() {
  const tamanoFuenteRem = parseFloat(leerVariableCss("--tp-font-size")) || 1.15;
  const colorTexto = leerVariableCss("--tp-color-texto") || "#ffffff";
  const opacidadFondo = parseFloat(leerVariableCss("--tp-opacidad-fondo"));
  return {
    tamanoFuenteRem,
    colorTexto: colorAHex(colorTexto),
    opacidadFondo: Number.isNaN(opacidadFondo) ? 0.55 : opacidadFondo,
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
      return datos;
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
}

function sincronizarControles(elementos, ajustes) {
  const { inputTamanoFuente, inputColorTexto, inputOpacidadFondo } = elementos;
  if (inputTamanoFuente) inputTamanoFuente.value = String(ajustes.tamanoFuenteRem);
  if (inputColorTexto) inputColorTexto.value = ajustes.colorTexto;
  if (inputOpacidadFondo) inputOpacidadFondo.value = String(ajustes.opacidadFondo);
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

function inicializarAjustes() {
  const elementos = obtenerElementos();
  const {
    panel,
    botonAlternar,
    botonCerrar,
    inputTamanoFuente,
    inputColorTexto,
    inputOpacidadFondo,
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
  if (!ajustesGuardados) {
    guardarAjustes(ajustesIniciales);
  }

  if (botonAlternar) {
    botonAlternar.addEventListener("click", () => alternarPanel(panel));
  } else {
    console.warn("ajustes: no se encontró #btn-alternar-ajustes en el DOM");
  }

  if (botonCerrar) {
    botonCerrar.addEventListener("click", () => ocultarPanel(panel));
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
    };
    aplicarAjustes(ajustes);
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
}

inicializarAjustes();
