import AVFoundation
import Foundation
import Observation

/// Detección de actividad de voz (VAD) por energía RMS, con histéresis de
/// dos umbrales, y enganche directo de la velocidad del teleprompter al
/// ritmo/energía de la voz — equivalente conceptual a `js/voz.js` T7/T8 de
/// la web, reimplementado sobre `AVAudioEngine` en vez de Web Audio API.
///
/// Usa un `AVAudioEngine` PROPIO con un tap sobre `inputNode`, separado de
/// la `AVCaptureSession` de `CamaraController` (T17/T18). Ambos consumen el
/// mismo micrófono físico a través de la misma `AVAudioSession` compartida
/// del proceso — ver la nota de diseño en `configurarSesionDeAudio()` sobre
/// por qué esto es seguro y no le "roba" el micrófono a la grabación de video.
@Observable
final class VozController {

    // MARK: - Constantes ajustables (calibración a ciegas)
    //
    // NOTA IMPORTANTE: este entorno de desarrollo NO tiene micrófono real
    // disponible (mismo límite documentado en toda la sesión para cámara).
    // Los valores de abajo son una ESTIMACIÓN razonable basada en el
    // comportamiento típico de RMS de voz humana captada por el micrófono
    // de un iPhone, y en los valores que la versión web terminó usando tras
    // DOS rondas de calibración real (T7/T8/T12 de la web). Es MUY probable
    // que necesiten un ajuste tras la primera prueba real del usuario en un
    // iPhone físico — no se debe interpretar esta calibración como
    // confirmada, exactamente igual que se documentó en la web.

    /// Umbral de energía RMS para ENTRAR en estado "hablando". Más alto que
    /// el umbral de salida a propósito (histéresis) — hace falta cruzar este
    /// umbral desde silencio para que el sistema decida que hay voz.
    private let umbralEntradaHabla: Double = 0.02

    /// Umbral de energía RMS para SALIR de "hablando" y volver a "silencio".
    /// Más bajo que `umbralEntradaHabla`: una vez hablando, el nivel tiene
    /// que caer más para considerarse silencio, evitando el parpadeo
    /// habla/silencio varias veces por segundo en un tono sostenido cerca
    /// de un único umbral.
    private let umbralSalidaHabla: Double = 0.01

    /// Nivel RMS esperado para una voz "fuerte"/rápida hablando cerca del
    /// micrófono del iPhone. El RMS crudo de un micrófono real vive en un
    /// rango pequeño (~0.015–0.15), NUNCA en [0,1] — este valor es el techo
    /// realista usado para remapear antes de calcular el factor de
    /// velocidad (ver la lección crítica en `remapearNivelAFraccion`).
    private let nivelHablaMaxEsperado: Double = 0.15

    /// Rango de factor de velocidad aplicado al teleprompter mientras se
    /// habla. Mismos valores con los que terminó la web tras su segunda
    /// calibración real (T12 de la web).
    private let factorMinimoHablando: Double = 0.7
    private let factorMaximoHablando: Double = 1.8

    /// Peso de la interpolación exponencial de suavizado (0–1). Más alto =
    /// reacciona más rápido pero con más saltos; más bajo = más suave pero
    /// con más retardo perceptible. 0.15 es el mismo valor usado en la web.
    private let pesoSuavizado: Double = 0.15

    /// Tamaño del buffer del tap, en frames. 1024 frames a 44.1kHz ≈ 23ms
    /// por callback — reacción rápida sin saturar el hilo de audio.
    private let tamanoBuffer: AVAudioFrameCount = 1024

    // MARK: - Estado observable

    /// Nivel RMS crudo del buffer más reciente, en su rango realista
    /// (~0.0–0.15+), NO normalizado a [0,1]. Se expone tal cual para
    /// depuración/indicador visual opcional.
    private(set) var nivel: Double = 0

    /// `true` mientras el VAD clasifica el audio actual como "habla" (tras
    /// aplicar histéresis de dos umbrales).
    private(set) var estaHablando = false

    /// `true` mientras el motor de audio está corriendo.
    private(set) var motorActivo = false

    /// Mensaje de error legible si el motor no pudo arrancar (permiso
    /// denegado, sesión de audio no configurable, etc.).
    private(set) var mensajeError: String?

    // MARK: - Dependencias e internos

    private let teleprompter: TeleprompterController
    private let engine = AVAudioEngine()

    /// Factor suavizado que se aplica de verdad al teleprompter. Converge
    /// hacia `factorObjetivo` con interpolación exponencial en cada callback
    /// del tap, en vez de saltar directo — evita aceleraciones/frenados
    /// bruscos perceptibles.
    private var factorSuavizado: Double = 0

    init(teleprompter: TeleprompterController) {
        self.teleprompter = teleprompter
    }

    // MARK: - Arranque

    /// Configura la `AVAudioSession` y arranca el `AVAudioEngine`. Debe
    /// llamarse solo después de que el permiso de micrófono ya fue
    /// concedido (reutiliza el permiso que `CamaraController` ya solicitó
    /// vía `AVCaptureDevice.requestAccess(for: .audio)` — T17/T22 comparten
    /// el mismo permiso del sistema, no hay un segundo prompt de micrófono
    /// para el usuario).
    func iniciar() {
        guard !motorActivo else { return }

        guard AVCaptureDevice.authorizationStatus(for: .audio) == .authorized else {
            mensajeError = "El acceso al micrófono no está autorizado; no se puede iniciar la detección de voz."
            return
        }

        do {
            try configurarSesionDeAudio()
            try configurarTap()
            engine.prepare()
            try engine.start()
            motorActivo = true
            mensajeError = nil
        } catch {
            mensajeError = "No fue posible iniciar la detección de voz: \(error.localizedDescription)"
            motorActivo = false
        }
    }

    func detener() {
        guard motorActivo else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        motorActivo = false
        nivel = 0
        estaHablando = false
        factorSuavizado = 0
        teleprompter.setVelocidad(0)
    }

    /// Configura la `AVAudioSession` compartida del proceso.
    ///
    /// DECISIÓN Y RAZONAMIENTO: se usa categoría `.playAndRecord` (no
    /// `.record` a secas) con modo `.videoRecording` y la opción
    /// `.mixWithOthers`. Razones:
    ///
    /// 1. `CamaraController` graba video CON audio a través de
    ///    `AVCaptureSession` + `AVCaptureMovieFileOutput`. `AVCaptureSession`
    ///    también configura la `AVAudioSession` compartida internamente
    ///    (categoría efectivamente `.playAndRecord`/`.record` con modo de
    ///    grabación de video) en cuanto tiene un input de audio activo. Si
    ///    `VozController` pidiera una categoría incompatible (ej. `.record`
    ///    a secas sin considerar el modo video), competiría por la
    ///    configuración de la sesión y podría interrumpir/reconfigurar el
    ///    audio de la grabación en curso. Usar `.playAndRecord` +
    ///    `.videoRecording` alinea la configuración de `VozController` con
    ///    lo que `AVCaptureSession` ya espera, en vez de pelear por ella.
    /// 2. `AVAudioEngine` y `AVCaptureSession` NO comparten el mismo "input
    ///    node" de forma exclusiva a nivel de API, pero SÍ comparten el
    ///    mismo hardware de micrófono a través de la misma `AVAudioSession`
    ///    del proceso — iOS permite que ambos framework-level consumers lean
    ///    del mismo hardware simultáneamente dentro del mismo proceso
    ///    siempre que la sesión esté configurada de forma consistente (no se
    ///    llama `setActive(false)` desde aquí mientras la cámara sigue
    ///    activa, y no se cambia a una categoría que excluya grabación).
    /// 3. `.mixWithOthers` se agrega para minimizar interrupciones si en el
    ///    futuro compite con audio de reproducción (ej. preview de un
    ///    archivo grabado) — no tiene costo funcional aquí.
    /// 4. NO se llama `setActive(true)` de forma agresiva si la sesión ya
    ///    está activa por la cámara: `setCategory` es idempotente y segura
    ///    de llamar de nuevo con las mismas opciones; `setActive(true)` con
    ///    `.notifyOthersOnDeactivation` tampoco interrumpe una sesión ya
    ///    activa del mismo proceso.
    private func configurarSesionDeAudio() throws {
        let sesion = AVAudioSession.sharedInstance()
        try sesion.setCategory(
            .playAndRecord,
            mode: .videoRecording,
            options: [.mixWithOthers, .allowBluetooth, .defaultToSpeaker]
        )
        try sesion.setActive(true, options: [])
    }

    private func configurarTap() throws {
        let inputNode = engine.inputNode
        let formato = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: tamanoBuffer, format: formato) { [weak self] buffer, _ in
            guard let self else { return }
            let rms = Self.calcularRMS(buffer: buffer)
            DispatchQueue.main.async {
                self.procesarNivel(rms)
            }
        }
    }

    // MARK: - Cálculo de energía RMS

    /// Calcula la energía RMS (root-mean-square) del buffer de audio —
    /// equivalente conceptual al `calcularRms` de la web sobre
    /// `getByteTimeDomainData`: suma de cuadrados normalizada por el número
    /// de muestras, raíz cuadrada del resultado. Si el buffer tiene varios
    /// canales, promedia el RMS de todos.
    private static func calcularRMS(buffer: AVAudioPCMBuffer) -> Double {
        guard let datosCanales = buffer.floatChannelData else { return 0 }
        let numeroCanales = Int(buffer.format.channelCount)
        let numeroMuestras = Int(buffer.frameLength)
        guard numeroMuestras > 0, numeroCanales > 0 else { return 0 }

        var sumaRmsCanales: Double = 0

        for canal in 0..<numeroCanales {
            let muestras = datosCanales[canal]
            var sumaCuadrados: Double = 0
            for indice in 0..<numeroMuestras {
                let valor = Double(muestras[indice])
                sumaCuadrados += valor * valor
            }
            let rmsCanal = sqrt(sumaCuadrados / Double(numeroMuestras))
            sumaRmsCanales += rmsCanal
        }

        return sumaRmsCanales / Double(numeroCanales)
    }

    // MARK: - Histéresis + remapeo + enganche a la velocidad

    /// Procesa un nivel RMS crudo recién calculado: aplica histéresis para
    /// clasificar habla/silencio, calcula el factor de velocidad objetivo
    /// (con el remapeo de rango obligatorio — ver la lección crítica más
    /// abajo), suaviza, y aplica el resultado al teleprompter. Se llama en
    /// el hilo principal (el tap despacha aquí vía `DispatchQueue.main`).
    private func procesarNivel(_ rms: Double) {
        nivel = rms

        // --- Histéresis de dos umbrales ---
        // Con un solo umbral, un nivel oscilando justo alrededor del corte
        // produce parpadeo habla/silencio varias veces por segundo. Con dos
        // umbrales (entrada > salida), una vez que se entra en "hablando"
        // hace falta caer por debajo del umbral MÁS BAJO para volver a
        // "silencio" — el rango entre ambos umbrales actúa como zona muerta
        // que no cambia el estado en ninguna dirección.
        if estaHablando {
            if rms < umbralSalidaHabla {
                estaHablando = false
            }
        } else {
            if rms > umbralEntradaHabla {
                estaHablando = true
            }
        }

        // --- Cálculo del factor objetivo ---
        let factorObjetivo: Double
        if !estaHablando {
            factorObjetivo = 0
        } else {
            // ============================================================
            // LECCIÓN CRÍTICA (T14 de la web, NO repetir en Swift):
            //
            // El RMS crudo (`nivel`) vive en un rango pequeño, típicamente
            // ~0.015–0.15 para voz real captada por el micrófono de un
            // iPhone — NUNCA en [0,1]. El bug real de la web fue multiplicar
            // ese nivel crudo directo contra `(factorMax - factorMin)`
            // asumiendo que ya estaba normalizado a [0,1]: con valores tan
            // chicos, casi toda la variación se perdía y el factor quedaba
            // pegado cerca del mínimo sin importar qué tan fuerte hablara el
            // usuario.
            //
            // LA CORRECCIÓN OBLIGATORIA (implementada abajo): remapear el
            // nivel crudo desde su rango realista
            // (`umbralEntradaHabla`...`nivelHablaMaxEsperado`) a una
            // fracción 0–1 clampeada, ANTES de aplicar la fórmula del
            // factor. La fórmula del factor NUNCA multiplica el `nivel`
            // crudo directamente contra `(factorMax - factorMin)`.
            // ============================================================
            let fraccionRemapeada = remapearNivelAFraccion(rms)
            factorObjetivo = factorMinimoHablando
                + fraccionRemapeada * (factorMaximoHablando - factorMinimoHablando)
        }

        // --- Suavizado (interpolación exponencial simple) ---
        factorSuavizado += (factorObjetivo - factorSuavizado) * pesoSuavizado

        // --- Recorte final de seguridad: nunca negativo, nunca > máximo ---
        let factorFinal = max(0, min(factorMaximoHablando, factorSuavizado))

        teleprompter.setVelocidad(factorFinal)
    }

    /// Remapea `nivel` (RMS crudo, rango realista
    /// `umbralEntradaHabla...nivelHablaMaxEsperado`) a una fracción 0–1
    /// clampeada. Este es EXACTAMENTE el paso que faltaba en el bug de la
    /// web (T14): sin este remapeo, el nivel crudo (~0.02–0.15) se
    /// multiplicaría casi siempre por una fracción minúscula del rango del
    /// factor, dejando el factor pegado cerca de `factorMinimoHablando`.
    private func remapearNivelAFraccion(_ nivelCrudo: Double) -> Double {
        let rango = nivelHablaMaxEsperado - umbralEntradaHabla
        guard rango > 0 else { return 0 }

        let fraccionSinClamp = (nivelCrudo - umbralEntradaHabla) / rango
        return max(0, min(1, fraccionSinClamp))
    }
}
