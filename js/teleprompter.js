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
}

montarTexto(GUION_EJEMPLO);
