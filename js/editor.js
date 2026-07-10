console.log("cargado: editor");

import { montarTexto, GUION_EJEMPLO } from "./teleprompter.js";

/** Clave fija de localStorage donde se persiste el guion del usuario (T6). */
const CLAVE_GUION = "teleprompter:guion";

function obtenerElementos() {
  const panel = document.getElementById("panel-editor");
  const textarea = document.getElementById("textarea-guion");
  const botonAlternar = document.getElementById("btn-alternar-editor");
  const botonGuardar = document.getElementById("btn-guardar-guion");
  const botonCerrar = document.getElementById("btn-cerrar-editor");
  return { panel, textarea, botonAlternar, botonGuardar, botonCerrar };
}

function cargarGuionGuardado() {
  try {
    return localStorage.getItem(CLAVE_GUION);
  } catch (error) {
    console.warn("editor: no se pudo leer localStorage", error);
    return null;
  }
}

function guardarGuion(texto) {
  try {
    localStorage.setItem(CLAVE_GUION, texto);
  } catch (error) {
    console.warn("editor: no se pudo escribir en localStorage", error);
  }
}

function mostrarEditor() {
  const { panel, textarea } = obtenerElementos();
  if (!panel || !textarea) return;
  // No se pierde el texto en curso: el textarea conserva lo que el usuario
  // ya haya escrito, no se resetea al guion montado en el teleprompter.
  panel.hidden = false;
  textarea.focus();
}

function ocultarEditor() {
  const { panel } = obtenerElementos();
  if (!panel) return;
  panel.hidden = true;
}

function alternarEditor() {
  const { panel } = obtenerElementos();
  if (!panel) return;
  if (panel.hidden) {
    mostrarEditor();
  } else {
    ocultarEditor();
  }
}

function inicializarEditor() {
  const { textarea, botonAlternar, botonGuardar, botonCerrar } = obtenerElementos();

  if (!textarea) {
    console.warn("editor: no se encontró #textarea-guion en el DOM");
    return;
  }

  // Guion inicial: el guardado en localStorage si existe, si no el de ejemplo.
  const guionGuardado = cargarGuionGuardado();
  const guionInicial =
    guionGuardado !== null && guionGuardado.trim().length > 0
      ? guionGuardado
      : GUION_EJEMPLO;

  textarea.value = guionInicial;
  montarTexto(guionInicial);

  if (botonAlternar) {
    botonAlternar.addEventListener("click", alternarEditor);
  } else {
    console.warn("editor: no se encontró #btn-alternar-editor en el DOM");
  }

  if (botonGuardar) {
    botonGuardar.addEventListener("click", () => {
      const texto = textarea.value;
      guardarGuion(texto);
      montarTexto(texto);
    });
  } else {
    console.warn("editor: no se encontró #btn-guardar-guion en el DOM");
  }

  if (botonCerrar) {
    botonCerrar.addEventListener("click", ocultarEditor);
  } else {
    console.warn("editor: no se encontró #btn-cerrar-editor en el DOM");
  }
}

inicializarEditor();
