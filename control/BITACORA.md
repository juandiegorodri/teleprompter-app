# Bitácora

*Historia del proyecto, append-only: una entrada por sesión, la más reciente ARRIBA, máximo
10 líneas cada una. NO se lee al arrancar sesión (para eso está ESTADO.md) — se consulta solo
para responder "¿por qué se hizo así?" o "¿cuándo pasó X?".*

## 2026-07-10 — instalación del sistema

- **Hecho**: sistema de proyecto instalado (control/, enjambre, CLAUDE.md) en carpeta nueva
  `teleprompter-app`.
- **Decidido**: sin backend, sin build step (HTML/CSS/JS vanilla); detección de ritmo de voz
  por energía de audio (Web Audio API), no Web Speech API; solo hosting local por ahora.
- **Pendiente**: plan de tareas del arquitecto y primera tarea (T1).
