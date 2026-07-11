# Política de privacidad de TelepromtCam

**Última actualización: 10 de julio de 2026**

TelepromtCam ("la app") es una aplicación para iPhone que funciona como teleprompter mientras graba
video con la cámara del dispositivo. Esta política explica, de forma clara y completa, qué datos usa
la app y qué hace (y qué no hace) con ellos.

## Resumen

TelepromtCam **no tiene servidor ni backend**, **no incluye ningún tipo de analítica ni rastreo**, y
**no recopila ni transmite ningún dato personal a ningún lugar**. Todo lo que la app usa para
funcionar —tu guion, tus preferencias y los videos que grabas— se queda **únicamente en tu
dispositivo**, bajo tu control.

## Permisos que usa la app y para qué

TelepromtCam solicita los siguientes permisos del sistema operativo, exclusivamente para las
funciones que ofrece:

- **Cámara**: se usa para mostrar la vista en vivo de la cámara y grabar el video mientras lees el
  guion en el teleprompter. La imagen de la cámara se procesa en el dispositivo y se graba
  directamente en el archivo de video local; no se envía a ningún servidor.
- **Micrófono**: se usa para dos cosas, ambas en el dispositivo: (1) grabar el audio del video que
  estás creando, y (2) medir el nivel de energía de tu voz (qué tan fuerte o rápido hablas) para
  ajustar automáticamente la velocidad de avance del texto del teleprompter. Esta medición **no es
  transcripción ni reconocimiento de voz**: la app no entiende ni interpreta lo que dices, solo
  detecta niveles de volumen y ritmo para sincronizar el texto con tu forma de hablar.
- **Acceso de escritura al carrete de Fotos**: se usa únicamente para guardar, si tú lo decides al
  terminar de grabar, el video resultante en tu app de Fotos. La app solo pide permiso de
  **escritura** (agregar fotos/videos a tu carrete); no lee, explora ni accede a tu biblioteca de
  fotos existente.

Estos permisos corresponden exactamente a los textos de uso ("usage strings") declarados en el
archivo de configuración de la app (`Info.plist`): `NSCameraUsageDescription`,
`NSMicrophoneUsageDescription` y `NSPhotoLibraryAddUsageDescription`.

## Qué datos recopila la app

**Ninguno.** De forma explícita:

- TelepromtCam **no tiene servidor, backend ni infraestructura en la nube** de ningún tipo. La app
  funciona completamente sin conexión a internet.
- TelepromtCam **no incluye ningún SDK de analítica, métricas de uso, rastreo publicitario ni
  herramientas de terceros** que recopilen información sobre ti o tu uso de la app.
- TelepromtCam **no recopila, no almacena en servidores externos y no transmite** tu guion, tus
  videos, tu voz, tu ubicación, tu identidad ni ningún otro dato personal a ningún tercero, servidor
  propio o servicio externo.
- El guion de texto que escribes o pegas en el editor se guarda **solo en tu dispositivo**, para que
  puedas retomarlo la próxima vez que abras la app.
- Las preferencias que configuras (calidad de video, fps, lente, tipografía, color, opacidad de
  fondo, velocidad del teleprompter) se guardan **solo en tu dispositivo**.
- Los videos que grabas existen únicamente en tu dispositivo: si eliges guardarlos, quedan en tu
  carrete de Fotos personal (protegido por el propio sistema operativo iOS); si eliges descartarlos,
  se eliminan y la app no conserva ninguna copia.

## Menores de edad

TelepromtCam no está dirigida específicamente a niños y no recopila ningún dato de ningún usuario,
independientemente de su edad, por las razones descritas arriba.

## Cambios a esta política

Si en el futuro la app cambia de forma que afecte el tratamiento de datos descrito aquí, esta
política se actualizará y se indicará la nueva fecha de "última actualización" en la parte superior
del documento.

## Contacto

Si tienes preguntas sobre esta política de privacidad, puedes escribir a:

`[correo de contacto pendiente — completar con el email que el desarrollador quiera usar para
soporte, por ejemplo soporte@tudominio.com]`
