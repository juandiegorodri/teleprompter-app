# Aprendizajes

*Errores cometidos y su lección, para no pagarlos dos veces. Lo alimenta el cronista al cierre.
Se consulta cuando algo falla o antes de una tarea parecida a una que ya falló. Si una lección
se convierte en regla permanente, se promueve al CLAUDE.md y se anota aquí que se promovió.*

*También se registran aquí las ESCALADAS de recursos: si un rol tuvo que subir de nivel
(ej. constructor de sonnet a opus), queda escrito en qué tarea y por qué — ese registro es el
que dice si la tabla de recursos del enjambre necesita ajuste.*

## Formato

### [AAAA-MM-DD] — [qué pasó, en una frase]

- **Error**: qué se hizo mal o qué falló.
- **Lección**: qué se entendió.
- **Regla derivada**: qué se hace distinto de ahora en adelante (si aplica).

---

### 2026-07-10 — Marcar tareas "verificadas" con lenguaje confiado sin poder ejercitarlas de verdad

- **Error**: durante toda la app nativa iOS (y parte de la web), muchas tareas se marcaron ✅ con
  evidencia del verificador redactada con confianza ("patrón estándar", "resuelto de raíz") cuando
  en realidad solo se había confirmado que COMPILA y que el código se ve correcto — sin poder
  ejercitar el comportamiento con hardware real. Dos veces seguidas (T22 y T28) se dio por resuelta
  la detección de voz y en ambas SIGUIÓ sin funcionar al probar. El diagnóstico real (conflicto
  `AVCaptureMovieFileOutput` + `AVCaptureAudioDataOutput`) apareció solo cuando el orquestador leyó
  el código a fondo tras el segundo fallo.
- **Lección**: "compila + revisión de código" NO es "funciona". Para cualquier tarea cuyo núcleo
  depende de hardware/entorno que este equipo no puede ejercitar (cámara, micrófono, permisos,
  instalación PWA), la evidencia debe decir explícitamente "PENDIENTE de confirmación funcional" y
  el lenguaje NO debe sonar concluyente. Además: tras un segundo fallo del mismo problema, NO
  delegar un tercer intento a ciegas — el orquestador debe investigar el código a fondo él mismo y
  formar una hipótesis concreta ANTES de volver a delegar.
- **Regla derivada**: (1) para features no ejercitables en este entorno, la DoD separa siempre
  "compila/revisado" (que sí se puede cerrar) de "funciona en dispositivo" (que queda PENDIENTE del
  usuario, nunca marcado por el agente). (2) Agregar OBSERVABILIDAD (ej. un medidor de nivel de
  audio visible) cuando un bug no es reproducible en el entorno, para que el usuario reporte datos
  reales en vez de iterar a ciegas. (3) Al segundo fallo del mismo síntoma, el orquestador lee el
  código completo y diagnostica antes de delegar de nuevo.
