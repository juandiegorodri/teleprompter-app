import AVFoundation
import Foundation
import Observation

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
final class CamaraController {

    /// Sesión de captura compartida. Pública para que T18 le agregue
    /// `AVCaptureMovieFileOutput` y T22 pueda leer del `entradaAudio`.
    let session = AVCaptureSession()

    /// Entrada de audio (micrófono), accesible para T22 (análisis de audio)
    /// sin tener que volver a buscar el dispositivo.
    private(set) var entradaAudio: AVCaptureDeviceInput?

    /// Entrada de video (cámara frontal), accesible para T18 (cambio de lente).
    private(set) var entradaVideo: AVCaptureDeviceInput?

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

        sesionConfigurada = true
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
