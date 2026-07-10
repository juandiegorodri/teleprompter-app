# Visión

*Se escribe una vez en el arranque, con las palabras del usuario. Solo cambia si el proyecto pivota.*

## Qué es

Una webapp que funciona como teleprompter mientras se graba video con la cámara del iPhone.
El texto avanza solo, sincronizado con la voz del usuario: si habla rápido el texto avanza
rápido, si habla lento avanza lento, y si deja de hablar el texto se detiene.

## Para quién

Una sola persona (el usuario), grabando video de sí misma hablando a cámara desde su iPhone,
usando Safari (PWA — sin instalar nada de App Store).

## Alcance v1 (3–5 funcionalidades, nada más)

1. Acceso a la cámara del iPhone y grabación de video desde el navegador (Safari iOS).
2. Teleprompter que avanza el texto automáticamente según la velocidad de habla detectada por
   el micrófono (más rápido si habla rápido, más lento si habla lento, se detiene si hay silencio).
3. Editor para escribir/editar el guion (texto del teleprompter).
4. Personalización de tipografía: tamaño y color del texto, y fondo del texto (translúcido u opaco).
5. Control de la proporción de pantalla entre la vista de cámara y el texto del teleprompter
   (cuánto espacio ocupa cada uno).

## Fuera de alcance (por ahora)

- Edición de video post-grabación (cortes, filtros, música).
- Compartir/exportar directo a redes sociales.
- Múltiples guiones guardados en la nube / cuentas de usuario / login.
- Soporte para Android u otros navegadores distintos de Safari iOS (se prueba y optimiza solo
  para iPhone/Safari; si funciona en otros, bien, pero no es el objetivo).
- Edición colaborativa o compartir el guion con otros.

## Cómo se ve el éxito

Abrir la app en Safari del iPhone, pegarla a la pantalla de inicio (PWA), escribir un guion,
ajustar tipografía/fondo/proporción a gusto, dar grabar, hablar a cámara viendo el teleprompter,
y que el texto avance de forma natural siguiendo el ritmo de la voz (se detiene si el usuario
para de hablar, acelera si habla más rápido) — y al terminar, tener un video grabado utilizable.
