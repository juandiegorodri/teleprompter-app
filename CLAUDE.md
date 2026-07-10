# teleprompter-app

Webapp para grabar video con la cámara del iPhone mientras un teleprompter muestra el guion y
avanza el texto automáticamente al ritmo de la voz del usuario. Detalle en control/VISION.md.

## Protocolo de arranque de sesión — SIEMPRE, antes de cualquier otra cosa

1. Lee `control/ESTADO.md` (≤ 60 líneas). Ahí está el hilo: qué funciona, qué está en curso, qué sigue.
2. Lee en `control/TAREAS.md` solo la tarea en curso.
3. Abre únicamente los archivos que `control/MAPA.md` señala para esa tarea.

**Prohibido**: explorar el repo completo, releer docs de control que la tarea no necesita,
leer BITACORA.md (es archivo histórico — solo se consulta para saber "¿por qué se hizo así?").

## El enjambre — delega según la tarea

La sesión principal ORQUESTA: lee estado, despacha y coordina. No implementa tareas enteras.

| Tarea | Agente | Recurso |
|---|---|---|
| Planear, decidir arquitectura, partir en tareas | `arquitecto` | opus · high |
| Ubicar código, responder "¿dónde está X?" | `Explore` | haiku |
| Implementar una tarea del plan | `constructor` | sonnet · medium |
| Probar contra la Definición de Hecho | `verificador` | sonnet · high |
| Cerrar la sesión (actualizar control/) | `cronista` | haiku |

Reglas de oro:
- **El que planea no ejecuta. El que ejecuta no se revisa a sí mismo.**
- Delegar = invocar el subagente con un prompt autocontenido (no ve esta conversación).
  Adoptar el rol en la conversación principal NO cuenta como delegar.
- Cada rol usa el menor esfuerzo que entregue calidad. Se escala UN nivel solo tras fallar dos
  veces la misma tarea (primero effort, luego modelo, editando temporalmente el frontmatter
  del agente y revirtiéndolo al cerrar), y se anota el porqué en APRENDIZAJES.md.
- Cambio trivial de una línea → hazlo directo, sin ceremonia de enjambre.

## Ciclo por tarea

tomar tarea en curso → constructor implementa → verificador prueba la Definición de Hecho
ítem por ítem → si pasa: el verificador marca la DoD con evidencia en TAREAS.md y la
ORQUESTADORA actualiza ESTADO.md ("Qué funciona" con fecha + siguiente paso) — hacerlo tras
CADA tarea es el seguro contra compactaciones → si no pasa: el reporte vuelve al constructor.
Nada se da por terminado sin que el verificador lo haya corrido de punta a punta. Bug fuera
de alcance → sección Bugs de TAREAS.md; no se arregla "de pasada".

## Protocolo de cierre de sesión — obligatorio

El `cronista`:
1. SOBRESCRIBE `control/ESTADO.md` con el siguiente paso concreto (nunca "seguir avanzando")
   y el contador de tareas cerradas (a las ~10, sugiere la pasada anti-deriva).
2. Añade entrada de ≤ 10 líneas a `control/BITACORA.md`.
3. Actualiza `control/MAPA.md` si la estructura cambió.
4. Registra errores y lecciones en `control/APRENDIZAJES.md`.

Sin cierre no hay hilo. Una sesión que no actualiza ESTADO.md le roba contexto a la siguiente.

## Reglas del repo

- Ningún doc nuevo por fuera de los 7 de `control/`. Si no cabe en los 7, va dentro de uno de los 7.
- Antes de crear un archivo de código, revisa en MAPA.md si ya existe dónde debería vivir.
- Decisión técnica no trivial → entrada ADR en `control/ARQUITECTURA.md` (fecha, decisión, porqué).
- Sin build step: HTML/CSS/JS vanilla servidos directo. Todo debe probarse en Safari iOS (o su
  emulación/responsive mode) antes de marcarse como hecho — es el único navegador objetivo.
- getUserMedia y MediaRecorder requieren HTTPS (o localhost) para funcionar — al probar local,
  usar `localhost` o un túnel HTTPS si se prueba desde el iPhone real.

## Comandos

- Correr: servir la carpeta con cualquier servidor estático, ej. `npx serve .` o
  `python3 -m http.server 8000`, y abrir `http://localhost:PUERTO`.
- Probar en iPhone real: exponer el localhost por HTTPS (ej. `npx localtunnel --port 8000` o
  ngrok) porque Safari iOS exige HTTPS para cámara/micrófono fuera de localhost.
- Lint/build: no aplica (sin build step).
