# Mapa de archivos

*Para saber dónde buscar SIN explorar el repo. Una línea por carpeta o archivo clave.
Lo actualiza el cronista al cierre cada vez que la estructura cambia. Si este mapa no
cuadra con la realidad, toca pasada anti-deriva.*

## Código (planeado — se confirma tarea por tarea)

| Ruta | Qué es / qué contiene | Rol que la toca |
|---|---|---|
| index.html | Entrada única de la app: estructura de la pantalla (cámara + overlay de texto + controles de edición/ajustes) | constructor |
| manifest.json | Manifiesto PWA (icono, nombre, modo standalone) para "agregar a pantalla de inicio" en iOS | constructor |
| css/estilos.css | Estilos generales, layout cámara/texto, controles de ajuste (tipografía, fondo, proporción) | constructor |
| js/camara.js | Acceso a `getUserMedia`, vista previa de cámara, `MediaRecorder` (iniciar/detener grabación) | constructor |
| js/voz.js | Web Audio API: mide actividad/energía del micrófono para detectar habla y su ritmo (VAD simple) | constructor |
| js/teleprompter.js | Lógica de scroll del texto: avanza según el ritmo detectado por voz.js, se detiene en silencio | constructor |
| js/editor.js | Editor del guion (crear/editar texto), guardado en `localStorage` | constructor |
| js/ajustes.js | Controles de tipografía (tamaño/color), fondo del texto (opaco/translúcido), proporción cámara/texto | constructor |

## Control y configuración

| Ruta | Qué es | Cuándo leerla |
|---|---|---|
| CLAUDE.md | Constitución: protocolos y reglas | Siempre (se carga sola) |
| control/ESTADO.md | El hilo del proyecto | Al arrancar CADA sesión |
| control/TAREAS.md | Backlog con Definición de Hecho | Al tomar o cerrar una tarea |
| control/VISION.md | Qué es el proyecto y su alcance | Solo ante dudas de alcance |
| control/ARQUITECTURA.md | Stack y decisiones (ADRs) | Antes de decisiones técnicas |
| control/BITACORA.md | Historia por sesión (append-only) | Solo para "¿por qué se hizo así?" |
| control/APRENDIZAJES.md | Errores + lecciones | Cuando algo falla o antes de tareas similares |
| .claude/agents/ | Los 5 roles del enjambre | No se leen; se delega en ellos |
