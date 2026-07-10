import AVFoundation
import Foundation
import Observation
import UIKit

/// Estado del permiso de cámara/micrófono, expuesto a la UI para mostrar
/// mensajes legibles sin necesidad de volver a llamar `requestAccess` en loop.
enum EstadoPermiso: Equatable {
    case noSolicitado
    case autorizado
    case denegado
    case restringido
}

/// Controla la `AVCaptureSession` de la cámara frontal + micrófono.
///
/// La sesión se arranca/para siempre en `colaSesion`, una cola serial dedicada,
/// nunca en el hilo principal (patrón estándar de AVFoundation). La `session`
/// y el `entradaAudio` quedan expuestos públicamente para que T18 (grabación)
/// y T22 (análisis de audio) puedan reutilizarlos sin reconfigurar la sesión.
@Observable
final class CamaraController: NSObject {

    /// Sesión de captura compartida. Pública para que T18 le agregue
    /// `AVCaptureMovieFileOutput` y T22 pueda leer del `entradaAudio`.
    let session = AVCaptureSession()

    /// Entrada de audio (micrófono), accesible para T22 (análisis de audio)
    /// sin tener que volver a buscar el dispositivo.
    private(set) var entradaAudio: AVCaptureDeviceInput?

    /// Entrada de video (cámara actual: frontal o trasera), accesible para
    /// T18 (cambio de lente).
    private(set) var entradaVideo: AVCaptureDeviceInput?

    /// Posición de la lente actualmente activa (frontal por defecto, T17).
    private(set) var posicionLenteActual: AVCaptureDevice.Position = .front

    /// Salida de grabación a archivo. Se agrega una sola vez en
    /// `configurarSesion()`; el mismo output se reutiliza entre grabaciones
    /// (grabar → detener → grabar de nuevo no reconfigura la sesión).
    private let movieFileOutput = AVCaptureMovieFileOutput()

    /// `true` mientras hay una grabación en curso. Controla la idempotencia
    /// de `iniciarGrabacion()`/`detenerGrabacion()`.
    private(set) var estaGrabando = false

    /// URL del archivo temporal de la última grabación terminada con éxito.
    private(set) var ultimaGrabacionURL: URL?

    /// Mensaje de error legible si la grabación falla al terminar o si
    /// `cambiarLente` no puede activar la lente pedida.
    private(set) var errorGrabacion: String?

    /// Estado observable del permiso combinado de cámara + micrófono.
    private(set) var estadoPermiso: EstadoPermiso = .noSolicitado

    /// Mensaje legible para mostrar en pantalla cuando el permiso no permite
    /// usar la cámara (denegado o restringido).
    private(set) var mensajeError: String?

    /// `true` mientras la sesión de captura está corriendo.
    private(set) var sesionActiva = false

    /// Cola serial dedicada para configurar y arrancar/parar la sesión.
    /// AVCaptureSession.startRunning()/stopRunning() son bloqueantes y NUNCA
    /// deben llamarse desde el hilo principal.
    private let colaSesion = DispatchQueue(label: "com.telepromtcam.camara.sesion")

    private var sesionConfigurada = false

    /// Solicita permisos de cámara y micrófono (dispara el prompt del sistema
    /// una sola vez por instalación) y, si se conceden, configura y arranca
    /// la sesión. Debe dispararse por una acción explícita del usuario
    /// (ej. tap en "Activar cámara"), nunca automáticamente al aparecer la vista.
    func solicitarPermisosYActivar() {
        let estadoActualVideo = AVCaptureDevice.authorizationStatus(for: .video)

        // Si ya sabemos que está denegado/restringido, NO volvemos a llamar
        // requestAccess (el sistema no vuelve a mostrar el prompt de todas
        // formas) — solo actualizamos el mensaje dirigiendo a Ajustes.
        if estadoActualVideo == .denied || estadoActualVideo == .restricted {
            actualizarEstado(desde: estadoActualVideo)
            return
        }

        AVCaptureDevice.requestAccess(for: .video) { [weak self] concedidoVideo in
            guard let self else { return }
            AVCaptureDevice.requestAccess(for: .audio) { concedidoAudio in
                DispatchQueue.main.async {
                    let estadoVideo = AVCaptureDevice.authorizationStatus(for: .video)
                    self.actualizarEstado(desde: estadoVideo)

                    if concedidoVideo && concedidoAudio {
                        self.configurarYArrancar()
                    } else if !concedidoAudio {
                        self.estadoPermiso = .denegado
                        self.mensajeError = "TelepromtCam necesita acceso al micrófono. Ve a Ajustes > Privacidad para habilitarlo."
                    }
                }
            }
        }
    }

    private func actualizarEstado(desde estadoVideo: AVAuthorizationStatus) {
        switch estadoVideo {
        case .authorized:
            estadoPermiso = .autorizado
            mensajeError = nil
        case .denied:
            estadoPermiso = .denegado
            mensajeError = "El acceso a la cámara está denegado. Ve a Ajustes > Privacidad > Cámara para habilitarlo."
        case .restricted:
            estadoPermiso = .restringido
            mensajeError = "El acceso a la cámara está restringido en este dispositivo (control parental o gestión corporativa)."
        case .notDetermined:
            estadoPermiso = .noSolicitado
            mensajeError = nil
        @unknown default:
            estadoPermiso = .denegado
            mensajeError = "No fue posible determinar el estado del permiso de cámara."
        }
    }

    /// Configura los inputs (una sola vez) y arranca la sesión, todo en la
    /// cola dedicada.
    private func configurarYArrancar() {
        colaSesion.async { [weak self] in
            guard let self else { return }

            if !self.sesionConfigurada {
                self.configurarSesion()
            }

            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.sesionActiva = true
                }
            }
        }
    }

    /// Arma la sesión con la cámara frontal y el micrófono. Se ejecuta en
    /// `colaSesion`.
    private func configurarSesion() {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .high

        // Cámara frontal.
        if let dispositivoVideo = AVCaptureDevice.default(
            .builtInWideAngleCamera, for: .video, position: .front
        ),
            let entrada = try? AVCaptureDeviceInput(device: dispositivoVideo),
            session.canAddInput(entrada)
        {
            session.addInput(entrada)
            entradaVideo = entrada
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.mensajeError = "No fue posible acceder a la cámara frontal de este dispositivo."
            }
        }

        // Micrófono.
        if let dispositivoAudio = AVCaptureDevice.default(for: .audio),
            let entrada = try? AVCaptureDeviceInput(device: dispositivoAudio),
            session.canAddInput(entrada)
        {
            session.addInput(entrada)
            entradaAudio = entrada
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.mensajeError = "No fue posible acceder al micrófono de este dispositivo."
            }
        }

        // Salida de grabación a archivo (T18). Se agrega una sola vez; el
        // preset/resolución usan el default de la sesión (`.high`, ya
        // definido arriba) — la calidad/fps configurables son T20.
        if session.canAddOutput(movieFileOutput) {
            session.addOutput(movieFileOutput)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.errorGrabacion = "No fue posible agregar la salida de grabación a la sesión."
            }
        }

        sesionConfigurada = true
    }

    // MARK: - Grabación (T18)
    //
    // Nota sobre la lección de la web: en Safari, `MediaRecorder` se cortaba
    // a los ~20s y hubo que mitigar con hacks de timeslice + WakeLock.
    // `AVCaptureMovieFileOutput` nativo no tiene ese bug — no se replican
    // esos hacks aquí. `isIdleTimerDisabled` se usa solo como buena práctica
    // para que la pantalla no se apague durante una grabación larga, no como
    // mitigación de ningún corte.

    /// Arranca la grabación a un archivo temporal único. Idempotente: si ya
    /// hay una grabación en curso, no hace nada (no permite doble-inicio).
    func iniciarGrabacion() {
        colaSesion.async { [weak self] in
            guard let self else { return }
            guard !self.movieFileOutput.isRecording else { return }

            let nombreArchivo = UUID().uuidString + ".mov"
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(nombreArchivo)

            DispatchQueue.main.async {
                self.errorGrabacion = nil
                self.ultimaGrabacionURL = nil
                self.estaGrabando = true
                UIApplication.shared.isIdleTimerDisabled = true
            }

            self.movieFileOutput.startRecording(to: url, recordingDelegate: self)
        }
    }

    /// Detiene la grabación en curso. Idempotente: si no hay grabación
    /// activa, no hace nada (no permite doble-detención inconsistente).
    func detenerGrabacion() {
        colaSesion.async { [weak self] in
            guard let self else { return }
            guard self.movieFileOutput.isRecording else { return }
            self.movieFileOutput.stopRecording()
        }
    }

    // MARK: - Cambio de lente (T18)

    /// Reconfigura el input de video a la cámara frontal o trasera. Remueve
    /// el input anterior ANTES de agregar el nuevo; si el nuevo falla (ej.
    /// no hay cámara trasera en este dispositivo), vuelve a agregar el
    /// input anterior para no dejar la sesión sin video.
    func cambiarLente(a posicion: AVCaptureDevice.Position) {
        colaSesion.async { [weak self] in
            guard let self else { return }
            guard posicion != self.posicionLenteActual else { return }

            let entradaAnterior = self.entradaVideo

            guard let dispositivoNuevo = AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: posicion
            ) else {
                DispatchQueue.main.async {
                    self.errorGrabacion = posicion == .back
                        ? "Este dispositivo no tiene cámara trasera disponible."
                        : "Este dispositivo no tiene cámara frontal disponible."
                }
                return
            }

            guard let entradaNueva = try? AVCaptureDeviceInput(device: dispositivoNuevo) else {
                DispatchQueue.main.async {
                    self.errorGrabacion = "No fue posible acceder a la cámara solicitada."
                }
                return
            }

            self.session.beginConfiguration()

            if let entradaAnterior {
                self.session.removeInput(entradaAnterior)
            }

            if self.session.canAddInput(entradaNueva) {
                self.session.addInput(entradaNueva)
                self.entradaVideo = entradaNueva
                self.posicionLenteActual = posicion
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.errorGrabacion = nil
                }
            } else {
                // El nuevo input falló: restauramos el anterior para no
                // dejar la sesión sin cámara.
                if let entradaAnterior, self.session.canAddInput(entradaAnterior) {
                    self.session.addInput(entradaAnterior)
                }
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.errorGrabacion = "No fue posible cambiar de cámara. Se mantiene la cámara actual."
                }
            }
        }
    }

    /// Detiene la sesión en la cola dedicada. Seguro de llamar aunque la
    /// sesión no esté corriendo.
    func detener() {
        colaSesion.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
            DispatchQueue.main.async {
                self.sesionActiva = false
            }
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension CamaraController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.estaGrabando = false
            UIApplication.shared.isIdleTimerDisabled = false

            if let error {
                self.errorGrabacion = "No fue posible completar la grabación: \(error.localizedDescription)"
                self.ultimaGrabacionURL = nil
            } else {
                self.errorGrabacion = nil
                self.ultimaGrabacionURL = outputFileURL
            }
        }
    }
}
