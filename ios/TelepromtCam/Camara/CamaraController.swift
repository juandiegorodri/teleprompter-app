import AVFoundation
import CoreMedia
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
/// nunca en el hilo principal (patrón estándar de AVFoundation).
///
/// T29 — pipeline de captura reescrito de raíz. ANTES la grabación usaba
/// `AVCaptureMovieFileOutput` y la detección de voz un `AVCaptureAudioDataOutput`
/// en la MISMA sesión. En iOS esos dos outputs NO coexisten de forma confiable:
/// `session.canAddOutput(audioDataOutput)` devuelve `false` cuando el
/// `MovieFileOutput` ya está presente, así que el output de audio nunca se
/// conectaba, el delegate de audio nunca recibía buffers, el RMS era siempre 0
/// y el texto no avanzaba (bug de T22 y T28).
///
/// AHORA no hay `MovieFileOutput`. Se graba con un `AVAssetWriter` alimentado
/// por `AVCaptureVideoDataOutput` (pista de video) + `AVCaptureAudioDataOutput`
/// (pista de audio). Como ya no hay `MovieFileOutput` con el que competir, el
/// audio SIEMPRE llega, y esos mismos buffers de audio sirven para dos cosas:
/// (a) escribir la pista de audio del `.mov`, y (b) alimentar el VAD de
/// `VozController` (vía `vozController?.procesarSampleBuffer(_:)`).
@Observable
final class CamaraController: NSObject {

    /// Sesión de captura compartida (la usa `PreviewCamara` para el preview).
    let session = AVCaptureSession()

    /// Entrada de audio (micrófono).
    private(set) var entradaAudio: AVCaptureDeviceInput?

    /// Entrada de video (cámara actual: frontal o trasera).
    private(set) var entradaVideo: AVCaptureDeviceInput?

    /// Posición de la lente actualmente activa (frontal por defecto).
    private(set) var posicionLenteActual: AVCaptureDevice.Position = .front

    /// Salida de datos de VIDEO en vivo (T29). Alimenta la pista de video del
    /// `AVAssetWriter`. Convive sin problemas con `audioDataOutput` en la
    /// misma sesión (a diferencia del viejo `MovieFileOutput`).
    let videoDataOutput = AVCaptureVideoDataOutput()

    /// Salida de datos de AUDIO en vivo (T29). Alimenta tanto la pista de
    /// audio del `AVAssetWriter` como el cálculo de RMS de `VozController`.
    let audioDataOutput = AVCaptureAudioDataOutput()

    /// Referencia al `VozController` al que se le reenvía cada buffer de audio
    /// para el VAD. `weak` para no crear un ciclo de retención (ContentView
    /// mantiene ambos controllers vivos; `VozController` no retiene a este).
    /// El wiring lo hace `ContentView` (`camara.vozController = voz`) antes de
    /// arrancar la detección.
    weak var vozController: VozController?

    /// `true` mientras hay una grabación en curso (observable, para la UI).
    private(set) var estaGrabando = false

    /// URL del archivo temporal de la última grabación terminada con éxito.
    private(set) var ultimaGrabacionURL: URL?

    /// Mensaje de error legible si la grabación falla o si `cambiarLente` no
    /// puede activar la lente pedida.
    private(set) var errorGrabacion: String?

    /// Estado observable del permiso combinado de cámara + micrófono.
    private(set) var estadoPermiso: EstadoPermiso = .noSolicitado

    /// Mensaje legible para mostrar en pantalla cuando el permiso no permite
    /// usar la cámara (denegado o restringido).
    private(set) var mensajeError: String?

    /// `true` mientras la sesión de captura está corriendo.
    private(set) var sesionActiva = false

    /// Cola serial dedicada para configurar/arrancar/parar la sesión.
    private let colaSesion = DispatchQueue(label: "com.telepromtcam.camara.sesion")

    /// Cola serial dedicada SOLO al delegate de `videoDataOutput` (T29b). La
    /// codificación H264 de los buffers 1080x1920 es pesada en CPU (aún más en
    /// el encoder por software del simulador); aislarla en su propia cola evita
    /// que el trabajo de video bloquee al de audio.
    private let colaVideo = DispatchQueue(label: "com.telepromtcam.camara.video", qos: .userInitiated)

    /// Cola serial dedicada SOLO al delegate de `audioDataOutput` (T29b). Al
    /// estar separada de `colaVideo`, los callbacks de audio (livianos, deben
    /// ser rápidos para alimentar el medidor de nivel de voz) nunca quedan en
    /// fila detrás de la codificación de video.
    private let colaAudio = DispatchQueue(label: "com.telepromtcam.camara.audio", qos: .userInitiated)

    /// Cola serial de CONTROL (T29b): corre `iniciarGrabacion`/`detenerGrabacion`
    /// y la limpieza del writer. Antes esa lógica corría en la cola compartida de
    /// sample buffers; ahora que video y audio tienen colas propias, el control
    /// vive en su propia cola para no interferir con ninguno de los dos caminos
    /// de captura. La consistencia del estado compartido la garantiza `lockWriter`.
    private let colaControl = DispatchQueue(label: "com.telepromtcam.camara.control")

    private var sesionConfigurada = false

    // MARK: - Estado del AVAssetWriter (protegido por `lockWriter`)

    /// Lock que protege el estado compartido del writer contra acceso concurrente
    /// REAL (T29b). Desde que video y audio corren en colas DISTINTAS a la vez,
    /// las lecturas/escrituras de `assetWriter`, `videoWriterInput`,
    /// `audioWriterInput`, `sesionWriterIniciada`, `grabando` y `urlGrabacionActual`
    /// pueden ocurrir simultáneamente. Se toma SIEMPRE de forma breve: solo para
    /// leer/mutar estas variables. El trabajo pesado (`append` de video/audio,
    /// creación del writer) SIEMPRE ocurre FUERA del lock.
    private let lockWriter = NSLock()

    private var assetWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var audioWriterInput: AVAssetWriterInput?
    /// `true` una vez que se llamó `startSession` con el primer buffer de video.
    private var sesionWriterIniciada = false
    /// Flag de grabación (separado del observable `estaGrabando`, que es para la
    /// UI en el hilo principal). Protegido por `lockWriter`.
    private var grabando = false
    private var urlGrabacionActual: URL?

    /// Ejecuta `body` con `lockWriter` tomado. Mantén el cuerpo MÍNIMO: solo
    /// lectura/mutación del estado compartido, nunca trabajo pesado.
    private func conLock<T>(_ body: () -> T) -> T {
        lockWriter.lock()
        defer { lockWriter.unlock() }
        return body()
    }

    // MARK: - Permisos

    /// Solicita permisos de cámara y micrófono y, si se conceden, configura y
    /// arranca la sesión. Debe dispararse por una acción explícita del usuario.
    func solicitarPermisosYActivar() {
        let estadoActualVideo = AVCaptureDevice.authorizationStatus(for: .video)

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

    /// Arma la sesión con la cámara frontal, el micrófono y los dos data
    /// outputs (video + audio). Se ejecuta en `colaSesion`.
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

        // Salida de datos de VIDEO (T29). `alwaysDiscardsLateVideoFrames` para
        // no acumular latencia si el writer se atrasa.
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: colaVideo)
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.errorGrabacion = "No fue posible agregar la salida de video a la sesión."
            }
        }

        // Salida de datos de AUDIO (T29). Ahora SÍ se puede agregar junto al
        // videoDataOutput (ya no hay MovieFileOutput con el que competir).
        audioDataOutput.setSampleBufferDelegate(self, queue: colaAudio)
        if session.canAddOutput(audioDataOutput) {
            session.addOutput(audioDataOutput)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.errorGrabacion = "No fue posible agregar la salida de audio para la detección de voz."
            }
        }

        configurarConexionVideo()

        sesionConfigurada = true
    }

    /// Fija orientación (vertical/portrait) y espejo (para la cámara frontal)
    /// en la conexión de video del `videoDataOutput`. Al fijarlas en la
    /// conexión, los `CMSampleBuffer` que llegan YA vienen rotados y espejados,
    /// así que el archivo grabado por el `AVAssetWriter` queda vertical y
    /// espejado como el preview sin necesidad de aplicar un `transform` extra.
    /// Se llama tras la configuración inicial y tras cada `cambiarLente`.
    private func configurarConexionVideo() {
        guard let connection = videoDataOutput.connection(with: .video) else { return }

        // Orientación vertical (portrait). En el SDK moderno (iOS 17+) se usa
        // `videoRotationAngle` (90° = portrait); se cae a `videoOrientation`
        // si la API nueva no está disponible.
        if connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        } else if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }

        // Espejo solo para la cámara frontal (igual que el preview de Apple).
        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = posicionLenteActual == .front
        }
    }

    // MARK: - Grabación con AVAssetWriter (T29)

    /// Arranca la grabación a un archivo temporal único, creando el
    /// `AVAssetWriter` y sus inputs. Idempotente. `startWriting`/`startSession`
    /// NO se llaman aquí: se hacen en el primer buffer de video que llegue
    /// estando grabando (ver `captureOutput`).
    func iniciarGrabacion() {
        colaControl.async { [weak self] in
            guard let self else { return }
            guard !self.conLock({ self.grabando }) else { return }

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + ".mov")

            let writer: AVAssetWriter
            do {
                writer = try AVAssetWriter(url: url, fileType: .mov)
            } catch {
                DispatchQueue.main.async {
                    self.errorGrabacion = "No fue posible crear el archivo de grabación: \(error.localizedDescription)"
                }
                return
            }

            // Dimensiones portrait (la conexión de video ya rota a 90°, así
            // que los buffers llegan verticales). 1080x1920 es un tamaño
            // razonable para el preset `.high`; si el buffer real difiere, el
            // writer reescala.
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 1080,
                AVVideoHeightKey: 1920,
            ]
            let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            videoInput.expectsMediaDataInRealTime = true

            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 1,
                AVSampleRateKey: 44100,
                AVEncoderBitRateKey: 128000,
            ]
            let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            audioInput.expectsMediaDataInRealTime = true

            if writer.canAdd(videoInput) { writer.add(videoInput) }
            if writer.canAdd(audioInput) { writer.add(audioInput) }

            // Publicar el estado compartido bajo lock (sección crítica mínima:
            // solo asignaciones; el writer y los inputs ya están construidos).
            self.conLock {
                self.assetWriter = writer
                self.videoWriterInput = videoInput
                self.audioWriterInput = audioInput
                self.sesionWriterIniciada = false
                self.urlGrabacionActual = url
                self.grabando = true
            }

            DispatchQueue.main.async {
                self.errorGrabacion = nil
                self.ultimaGrabacionURL = nil
                self.estaGrabando = true
                UIApplication.shared.isIdleTimerDisabled = true
            }
        }
    }

    /// Detiene la grabación en curso, finaliza el `AVAssetWriter` y entrega la
    /// URL (o un error) por el mismo contrato que antes (`ultimaGrabacionURL`).
    /// Idempotente.
    func detenerGrabacion() {
        colaControl.async { [weak self] in
            guard let self else { return }

            // Snapshot atómico del estado compartido y apagado de `grabando`
            // bajo lock (sección crítica mínima). Copiamos las referencias que
            // necesitamos para operar FUERA del lock.
            let (estabaGrabando, writer, sesionIniciada, url, videoInput, audioInput):
                (Bool, AVAssetWriter?, Bool, URL?, AVAssetWriterInput?, AVAssetWriterInput?) = self.conLock {
                    let g = self.grabando
                    if g { self.grabando = false }
                    return (
                        g,
                        self.assetWriter,
                        self.sesionWriterIniciada,
                        self.urlGrabacionActual,
                        self.videoWriterInput,
                        self.audioWriterInput
                    )
                }

            guard estabaGrabando else { return }

            guard let writer else {
                self.finalizarUISinGrabacion()
                return
            }

            // Si nunca llegó a escribir (p. ej. se detuvo antes del primer
            // buffer de video), no se puede finishWriting desde `.unknown`:
            // se cancela y se reporta.
            guard sesionIniciada, writer.status == .writing else {
                if writer.status == .writing || writer.status == .unknown {
                    writer.cancelWriting()
                }
                self.limpiarWriter()
                DispatchQueue.main.async {
                    self.errorGrabacion = "La grabación fue demasiado corta para guardarse."
                    self.ultimaGrabacionURL = nil
                    self.estaGrabando = false
                    UIApplication.shared.isIdleTimerDisabled = false
                }
                return
            }

            videoInput?.markAsFinished()
            audioInput?.markAsFinished()

            writer.finishWriting {
                let completado = writer.status == .completed
                self.colaControl.async {
                    self.limpiarWriter()
                }
                DispatchQueue.main.async {
                    if completado {
                        self.errorGrabacion = nil
                        self.ultimaGrabacionURL = url
                    } else {
                        self.errorGrabacion = "No fue posible completar la grabación: \(writer.error?.localizedDescription ?? "error desconocido")."
                        self.ultimaGrabacionURL = nil
                    }
                    self.estaGrabando = false
                    UIApplication.shared.isIdleTimerDisabled = false
                }
            }
        }
    }

    /// Resetea las referencias del writer bajo `lockWriter`. Puede llamarse desde
    /// cualquier cola; el lock garantiza que no colisione con lecturas de los
    /// callbacks de video/audio.
    private func limpiarWriter() {
        conLock {
            assetWriter = nil
            videoWriterInput = nil
            audioWriterInput = nil
            sesionWriterIniciada = false
            urlGrabacionActual = nil
        }
    }

    /// Cierra el estado de UI de grabación cuando no hubo writer que finalizar.
    private func finalizarUISinGrabacion() {
        limpiarWriter()
        DispatchQueue.main.async {
            self.estaGrabando = false
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    /// Limpia `ultimaGrabacionURL` (llamado por `ModalResultado` tras guardar
    /// en Fotos o descartar) para cerrar el `.fullScreenCover`.
    func limpiarUltimaGrabacion() {
        ultimaGrabacionURL = nil
    }

    // MARK: - Cambio de lente

    /// Reconfigura el input de video a la cámara frontal o trasera. Si el nuevo
    /// falla, restaura el anterior para no dejar la sesión sin video.
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
                self.configurarConexionVideo()
                DispatchQueue.main.async {
                    self.errorGrabacion = nil
                }
            } else {
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

    // MARK: - Calidad y fps

    /// Aplica un nuevo `AVCaptureSession.Preset`, validando con
    /// `canSetSessionPreset` antes de asignarlo.
    func aplicarCalidadCamara(_ calidad: CalidadCamara) {
        colaSesion.async { [weak self] in
            guard let self else { return }
            let preset = calidad.preset

            guard self.session.canSetSessionPreset(preset) else {
                DispatchQueue.main.async {
                    self.errorGrabacion = "La calidad \(calidad.label) no está disponible en este dispositivo. Se mantiene la calidad actual."
                }
                return
            }

            self.session.beginConfiguration()
            self.session.sessionPreset = preset
            self.session.commitConfiguration()

            DispatchQueue.main.async {
                self.errorGrabacion = nil
            }
        }
    }

    /// Aplica un nuevo fps al dispositivo de video activo, haciendo clamp al
    /// rango soportado más cercano si el valor pedido no cabe.
    func aplicarFPS(_ fps: FPS) {
        colaSesion.async { [weak self] in
            guard let self else { return }
            guard let device = self.entradaVideo?.device else { return }

            let fpsPedido = Double(fps.rawValue)
            let rangos = device.activeFormat.videoSupportedFrameRateRanges

            guard !rangos.isEmpty else {
                DispatchQueue.main.async {
                    self.errorGrabacion = "Este dispositivo no reporta rangos de fps soportados."
                }
                return
            }

            var fpsFinal: Double
            if rangos.contains(where: { ($0.minFrameRate...$0.maxFrameRate).contains(fpsPedido) }) {
                fpsFinal = fpsPedido
            } else {
                var mejorDistancia = Double.greatestFiniteMagnitude
                var mejorClamp = fpsPedido
                for rango in rangos {
                    let clamp = min(max(fpsPedido, rango.minFrameRate), rango.maxFrameRate)
                    let distancia = abs(clamp - fpsPedido)
                    if distancia < mejorDistancia {
                        mejorDistancia = distancia
                        mejorClamp = clamp
                    }
                }
                fpsFinal = mejorClamp
            }

            guard fpsFinal > 0 else { return }

            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }

                let duracion = CMTime(value: 1, timescale: Int32(fpsFinal))
                device.activeVideoMinFrameDuration = duracion
                device.activeVideoMaxFrameDuration = duracion

                DispatchQueue.main.async {
                    self.errorGrabacion = nil
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorGrabacion = "No fue posible ajustar los fps: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Detiene la sesión en la cola dedicada.
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

// MARK: - Delegates de sample buffers (video + audio)

extension CamaraController: AVCaptureVideoDataOutputSampleBufferDelegate,
    AVCaptureAudioDataOutputSampleBufferDelegate
{
    /// `videoDataOutput` llama en `colaVideo` y `audioDataOutput` en `colaAudio`
    /// (T29b): son colas seriales DISTINTAS, así que las dos rutas pueden correr
    /// a la vez. Se distingue por identidad del output. El estado compartido del
    /// writer se lee/muta SIEMPRE bajo `lockWriter`, en secciones críticas
    /// mínimas; el trabajo pesado (`append`) ocurre FUERA del lock.
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        if output === audioDataOutput {
            // 1) SIEMPRE y PRIMERO alimentar el VAD, se esté grabando o no, ANTES
            //    de tocar cualquier estado compartido protegido por lock. Así el
            //    medidor de nivel nunca depende de si `lockWriter` está libre ni
            //    de lo que esté haciendo el camino de video.
            vozController?.procesarSampleBuffer(sampleBuffer)

            // 2) Escribir la pista de audio, solo si el writer ya arrancó su
            //    sesión (con un buffer de video) y está en `.writing`. Snapshot
            //    del estado compartido bajo lock; el `append` va fuera del lock.
            let (debeEscribir, writer, audioInput): (Bool, AVAssetWriter?, AVAssetWriterInput?) = conLock {
                (grabando && sesionWriterIniciada, assetWriter, audioWriterInput)
            }
            guard debeEscribir,
                let writer,
                let audioInput,
                writer.status == .writing,
                audioInput.isReadyForMoreMediaData
            else { return }

            audioInput.append(sampleBuffer)

        } else if output === videoDataOutput {
            // Snapshot bajo lock. Si es el primer buffer de video estando
            // grabando, arrancar la sesión del writer DENTRO del lock (mutación
            // única y barata de `sesionWriterIniciada`); el `append` pesado se
            // hace después, fuera del lock.
            let (writer, videoInput): (AVAssetWriter?, AVAssetWriterInput?) = conLock {
                guard grabando, let writer = assetWriter else { return (nil, nil) }

                if !sesionWriterIniciada {
                    guard writer.status == .unknown else { return (nil, nil) }
                    if writer.startWriting() {
                        writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
                        sesionWriterIniciada = true
                    } else {
                        return (nil, nil)
                    }
                }

                return (writer, videoWriterInput)
            }

            guard let writer,
                let videoInput,
                writer.status == .writing,
                videoInput.isReadyForMoreMediaData
            else { return }

            videoInput.append(sampleBuffer)
        }
    }
}
