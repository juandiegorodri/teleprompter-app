# Bitácora

*Historia del proyecto, append-only: una entrada por sesión, la más reciente ARRIBA, máximo
10 líneas cada una. NO se lee al arrancar sesión (para eso está ESTADO.md) — se consulta solo
para responder "¿por qué se hizo así?" o "¿cuándo pasó X?".*

## 2026-07-10 — v1 implementada completa (T1-T11)

- **Hecho**: las 11 tareas del plan implementadas (esqueleto, cámara, grabación, teleprompter con
  scroll, editor, detección de voz + enganche, ajustes de estilo/proporción, PWA/manifest).
- **Decidido**: sin cámara/mic físicos en el entorno de desarrollo, la verificación fue por
  revisión de código exhaustiva en vez de prueba visual en la mayoría de tareas (T2-T11); las
  herramientas de navegador interactivo estuvieron caídas gran parte de la sesión.
- **Pendiente**: pase de verificación completo en iPhone real (o navegador con cámara) antes de
  entregar; pasada anti-deriva (11 tareas cerradas); arreglar bug #1 (modo voz sin detección activa).

## 2026-07-10 — instalación del sistema

- **Hecho**: sistema de proyecto instalado (control/, enjambre, CLAUDE.md) en carpeta nueva
  `teleprompter-app`.
- **Decidido**: sin backend, sin build step (HTML/CSS/JS vanilla); detección de ritmo de voz
  por energía de audio (Web Audio API), no Web Speech API; solo hosting local por ahora.
- **Pendiente**: plan de tareas del arquitecto y primera tarea (T1).
