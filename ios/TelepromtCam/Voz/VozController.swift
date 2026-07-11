import AVFoundation
import CoreMedia
import Foundation
import Observation

/// Detección de actividad de voz (VAD) por energía RMS, con histéresis de
/// dos umbrales, y enganche directo de la velocidad del teleprompter al
/// ritmo/energía de la voz — equivalente conceptual a `js/voz.js` T7/T8 de
/// la web.
///
/// T29: la fuente de audio YA NO es un `AVAudioEngine` propio, ni este
/// controller es el delegate directo del `AVCaptureAudioDataOutput`. Un
/// `AVCaptureAudioDataOutput` admite UN solo delegate, y ahora ese delegate es
/// `CamaraController` (que necesita los buffers de audio para escribir la pista
/// de audio del `AVAssetWriter`). Por eso `CamaraController` recibe cada buffer
/// y se lo REENVÍA a este controller llamando `procesarSampleBuffer(_:)`. Toda
/// la lógica de VAD (RMS, histéresis, remapeo de rango — la lección crítica —,
/// suavizado, enganche a `setVelocidad`) se conserva idéntica; solo cambia de
/// dónde llega el buffer.
@Observable
final class VozController: NSObject {

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
    /// T29: bajado a 0.01 para MÁXIMA sensibilidad inicial. Con el medidor de
    /// nivel visible en la UI (T29 punto 3), el usuario puede reportar el valor
    /// real de `nivel` al hablar/callar y calibrar este umbral con datos reales.
    private let umbralEntradaHabla: Double = 0.01

    /// Umbral de energía RMS para SALIR de "hablando" y volver a "silencio".
    /// Más bajo que `umbralEntradaHabla`: una vez hablando, el nivel tiene
    /// que caer más para considerarse silencio, evitando el parpadeo
    /// habla/silencio varias veces por segundo en un tono sostenido cerca
    /// de un único umbral.
    /// T29: bajado a 0.005 (más bajo que el de entrada, histéresis).
    private let umbralSalidaHabla: Double = 0.005

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

    // MARK: - Estado observable

    /// Nivel RMS crudo del buffer más reciente, en su rango realista
    /// (~0.0–0.15+), NO normalizado a [0,1]. Se expone tal cual para
    /// depuración/indicador visual opcional.
    private(set) var nivel: Double = 0

    /// `true` mientras el VAD clasifica el audio actual como "habla" (tras
    /// aplicar histéresis de dos umbrales).
    private(set) var estaHablando = false

    /// `true` mientras la detección de voz está registrada como delegate
    /// del `AVCaptureAudioDataOutput` y recibiendo buffers.
    private(set) var motorActivo = false

    /// Mensaje de error legible si no se pudo registrar como delegate
    /// (permiso denegado, etc.).
    private(set) var mensajeError: String?

    // MARK: - Dependencias e internos

    private let teleprompter: TeleprompterController

    /// Factor suavizado que se aplica de verdad al teleprompter. Converge
    /// hacia `factorObjetivo` con interpolación exponencial en cada buffer
    /// de audio recibido, en vez de saltar directo — evita
    /// aceleraciones/frenados bruscos perceptibles.
    private var factorSuavizado: Double = 0

    init(teleprompter: TeleprompterController) {
        self.teleprompter = teleprompter
    }

    // MARK: - Arranque

    /// Activa el VAD. Ya NO se registra como delegate de ningún output (T29):
    /// `CamaraController` es el delegate del `AVCaptureAudioDataOutput` y le
    /// reenvía cada buffer a `procesarSampleBuffer(_:)`. Aquí solo se marca el
    /// flag `motorActivo` (que hace que `procesarSampleBuffer` procese en vez
    /// de descartar) tras verificar el permiso de micrófono.
    func iniciar() {
        guard !motorActivo else { return }

        guard AVCaptureDevice.authorizationStatus(for: .audio) == .authorized else {
            mensajeError = "El acceso al micrófono no está autorizado; no se puede iniciar la detección de voz."
            return
        }

        motorActivo = true
        mensajeError = nil
    }

    func detener() {
        guard motorActivo else { return }
        motorActivo = false
        nivel = 0
        estaHablando = false
        factorSuavizado = 0
        teleprompter.setVelocidad(0)
    }

    // MARK: - Entrada de audio (reenviada por CamaraController)

    /// Punto de entrada del audio (T29): `CamaraController` llama a este método
    /// desde su callback de `AVCaptureAudioDataOutput` (en su cola de sample
    /// buffers), pasando cada `CMSampleBuffer` de audio. Calcula el RMS aquí
    /// (fuera del hilo principal, como antes hacía el delegate) y despacha a
    /// `main` para `procesarNivel`, que toca estado `@Observable`.
    func procesarSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard motorActivo else { return }
        let rms = Self.calcularRMS(sampleBuffer: sampleBuffer)
        DispatchQueue.main.async { [weak self] in
            self?.procesarNivel(rms)
        }
    }

    // MARK: - Cálculo de energía RMS

    /// Extrae las muestras PCM de un `CMSampleBuffer` de audio y calcula su
    /// energía RMS (root-mean-square) — equivalente conceptual al
    /// `calcularRms` de la web sobre `getByteTimeDomainData`: suma de
    /// cuadrados normalizada por el número de muestras, raíz cuadrada del
    /// resultado.
    ///
    /// DECISIÓN SOBRE LA API DE EXTRACCIÓN: se usa la función C clásica
    /// `CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer`, no el
    /// método moderno `CMSampleBuffer.audioBufferList` (disponible solo en
    /// SDKs muy recientes con el nuevo overlay de Swift para CoreMedia) —
    /// se prioriza la forma que compila de manera consistente en el SDK de
    /// Xcode 26.6 usado en este entorno.
    ///
    /// DECISIÓN SOBRE EL FORMATO: `AVCaptureAudioDataOutput.audioSettings`
    /// está `API_UNAVAILABLE` en iOS (solo se puede fijar en macOS), así
    /// que NO se puede forzar Float32 de antemano — hay que trabajar con el
    /// formato que iOS entregue por defecto (típicamente PCM Int16
    /// intercalado). Se lee el `CMFormatDescription` del propio
    /// `sampleBuffer` para saber si las muestras son Float32 o enteras, y
    /// en caso entero se normaliza a `[-1, 1]` dividiendo por el rango
    /// máximo del ancho de bits real (`mBitsPerChannel`), no asumiendo
    /// Int16 a ciegas.
    private static func calcularRMS(sampleBuffer: CMSampleBuffer) -> Double {
        var blockBuffer: CMBlockBuffer?
        var audioBufferList = AudioBufferList()

        let status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: nil,
            bufferListOut: &audioBufferList,
            bufferListSize: MemoryLayout<AudioBufferList>.size,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
            blockBufferOut: &blockBuffer
        )

        guard status == noErr else { return 0 }
        guard let mData = audioBufferList.mBuffers.mData else { return 0 }

        guard
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
            let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)?.pointee
        else { return 0 }

        let numeroBytes = Int(audioBufferList.mBuffers.mDataByteSize)
        let esFloat = (asbd.mFormatFlags & kAudioFormatFlagIsFloat) != 0
        let bitsPorCanal = Int(asbd.mBitsPerChannel)

        var sumaCuadrados: Double = 0
        var numeroMuestras = 0

        if esFloat, bitsPorCanal == 32 {
            numeroMuestras = numeroBytes / MemoryLayout<Float32>.size
            guard numeroMuestras > 0 else { return 0 }
            let muestras = mData.assumingMemoryBound(to: Float32.self)
            for indice in 0..<numeroMuestras {
                let valor = Double(muestras[indice])
                sumaCuadrados += valor * valor
            }
        } else if bitsPorCanal == 16 {
            numeroMuestras = numeroBytes / MemoryLayout<Int16>.size
            guard numeroMuestras > 0 else { return 0 }
            let muestras = mData.assumingMemoryBound(to: Int16.self)
            for indice in 0..<numeroMuestras {
                let valor = Double(muestras[indice]) / Double(Int16.max)
                sumaCuadrados += valor * valor
            }
        } else if bitsPorCanal == 32 {
            // PCM entero de 32 bits (poco común pero posible).
            numeroMuestras = numeroBytes / MemoryLayout<Int32>.size
            guard numeroMuestras > 0 else { return 0 }
            let muestras = mData.assumingMemoryBound(to: Int32.self)
            for indice in 0..<numeroMuestras {
                let valor = Double(muestras[indice]) / Double(Int32.max)
                sumaCuadrados += valor * valor
            }
        } else {
            return 0
        }

        return sqrt(sumaCuadrados / Double(numeroMuestras))
    }

    // MARK: - Histéresis + remapeo + enganche a la velocidad

    /// Procesa un nivel RMS crudo recién calculado: aplica histéresis para
    /// clasificar habla/silencio, calcula el factor de velocidad objetivo
    /// (con el remapeo de rango obligatorio — ver la lección crítica más
    /// abajo), suaviza, y aplica el resultado al teleprompter. Debe
    /// llamarse siempre en el hilo principal — `captureOutput` despacha
    /// aquí vía `DispatchQueue.main`, igual que antes hacía el tap del
    /// `AVAudioEngine`.
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
