# Resumen para el cuestionario "App Privacy" de App Store Connect

Guía práctica para llenar el cuestionario de privacidad de la app en App Store Connect
(Recopilación de datos → "App Privacy"). Coherente con `politica-privacidad.md`: TelepromtCam no
tiene servidor, no transmite datos fuera del dispositivo y no tiene analítica.

## Criterio de Apple: qué cuenta como "recolección"

La definición de Apple es explícita: **"Collection" (recolección) se refiere a transmitir datos
fuera del dispositivo del usuario**, de forma que el desarrollador, un tercero, o cualquier proceso
externo tenga acceso a ellos (ya sea en tiempo real o guardado en un servidor). El uso puramente
local de datos —guardarlos, procesarlos o mostrarlos únicamente dentro del propio dispositivo, sin
que salgan de él— **no cuenta como recolección** bajo esta definición.

TelepromtCam graba video y audio, mide el nivel de energía de la voz, y guarda un guion de texto y
preferencias — pero todo eso ocurre y permanece exclusivamente en el dispositivo del usuario. Nada
se envía a un servidor propio, a un SDK de terceros ni a ningún servicio externo. Por eso, para
**todas** las categorías del cuestionario, la respuesta correcta es **"Data Not Collected"** (No se
recopilan datos).

## Mapeo categoría por categoría

| Categoría del cuestionario | Respuesta | Por qué |
|---|---|---|
| **Contact Info** (nombre, email, teléfono, dirección, etc.) | Data Not Collected | La app no tiene registro de usuario, cuentas ni formularios de contacto. |
| **Health & Fitness** | Data Not Collected | La app no accede a HealthKit ni a ningún dato de salud o actividad física. |
| **Financial Info** | Data Not Collected | No hay pagos, compras dentro de la app, ni datos financieros de ningún tipo. |
| **Location** | Data Not Collected | La app no solicita permiso de ubicación (no aparece `NSLocationWhenInUseUsageDescription` en `Info.plist`) ni usa GPS/CoreLocation. |
| **Sensitive Info** (raza, orientación, religión, etc.) | Data Not Collected | La app no solicita ni procesa ningún dato sensible. |
| **Contacts** | Data Not Collected | La app no accede a la libreta de contactos del dispositivo. |
| **User Content** — incluye Photos or Videos, Audio Data, Other User Content | Data Not Collected | **Punto que requiere justificación**: la app sí graba video y audio (cámara y micrófono), y sí escribe el video resultante en el carrete de Fotos del usuario (`PHPhotoLibrary`, permiso de solo escritura). Pero según el criterio de Apple citado arriba, "recolección" es sobre **transmisión/recolección fuera del dispositivo**, no sobre el uso o almacenamiento local. El video y el audio grabados nunca salen del dispositivo: no se suben a ningún servidor, no pasan por ningún SDK de terceros, y el propio desarrollador no tiene acceso a ellos. Por lo tanto, aunque la app "usa" Photos/Videos y Audio localmente, **no los "recopila"** en el sentido que pregunta el formulario, y la respuesta correcta sigue siendo Data Not Collected. (Si Apple pidiera aclarar el uso de cámara/micrófono/Fotos en la revisión, la respuesta es: uso 100% local, sin transmisión, ver política de privacidad.) |
| **Browsing History** | Data Not Collected | La app no tiene navegador embebido ni rastrea historial de navegación. |
| **Search History** | Data Not Collected | La app no tiene función de búsqueda que se registre o transmita. |
| **Identifiers** (User ID, Device ID) | Data Not Collected | La app no genera ni transmite identificadores de usuario o dispositivo; no hay analítica ni backend que los necesite. |
| **Purchases** | Data Not Collected | No hay compras dentro de la app ni historial de compras. |
| **Usage Data** (interacciones, tiempo en la app, etc.) | Data Not Collected | No hay SDK de analítica ni telemetría de uso de ningún tipo. |
| **Diagnostics** (crash logs, performance data) | Data Not Collected | La app no integra ningún servicio de crash reporting ni recolección de diagnósticos de terceros (solo los reportes de crash agregados y anónimos que gestiona Apple a nivel de sistema operativo, que no cuentan como recolección del desarrollador). |
| **Other Data** | Data Not Collected | No aplica ninguna otra categoría de datos. |

## Pasos sugeridos al llenar el formulario en App Store Connect

1. En la sección "App Privacy", seleccionar **"No, we do not collect data from this app"** cuando
   Apple pregunte si la app recopila datos.
2. Si el flujo de Apple pide justificar explícitamente el uso de cámara, micrófono o Fotos (aparece
   en algunas versiones del formulario como pregunta de contexto, no como "recolección"), usar la
   explicación de la fila "User Content" de la tabla anterior.
3. Guardar y publicar la declaración de privacidad junto con el resto de la ficha de la app.
4. Mantener este documento y `politica-privacidad.md` sincronizados si en el futuro se agrega
   cualquier función que sí transmita datos (por ejemplo, un backend, analítica, o compartir en
   redes) — en ese caso, este resumen y el cuestionario en App Store Connect deben actualizarse antes
   de publicar esa versión.
