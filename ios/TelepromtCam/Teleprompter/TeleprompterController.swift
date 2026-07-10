import Foundation
import Observation

/// Guion de ejemplo hardcodeado hasta que T23 agregue el editor con
/// persistencia real y sobreescriba `texto`.
private let guionDeEjemplo = """
Bienvenido a TelepromtCam.

Este es un guion de ejemplo para probar el desplazamiento automático \
del teleprompter mientras grabas con la cámara frontal.

El texto avanza a una velocidad configurable en Ajustes, y se detendrá \
solo al llegar al final.

Más adelante, el control por voz (T22) podrá acelerar o frenar el \
desplazamiento según qué tan rápido estés hablando, y el editor (T23) \
te permitirá escribir y guardar tu propio guion.

Por ahora, disfruta viendo cómo se desplaza este texto de prueba de \
manera fluida, sin importar la carga del dispositivo, porque el avance \
se calcula con delta de tiempo real y no con conteo de frames.
"""

/// Controla el desplazamiento vertical automático del texto del
/// teleprompter. El avance se calcula con **delta de tiempo real**
/// (timestamp a timestamp), exactamente como el `requestAnimationFrame`
/// con delta de tiempo que se validó en la web (T5) — nunca por conteo de
/// frames ni con un incremento fijo por tick, porque eso acelera/frena
/// según la carga del dispositivo (FPS variable).
///
/// La vista (`OverlayTeleprompter`) es responsable de llamar a `avanzar(hasta:)`
/// en cada tick de un `TimelineView(.animation)`, pasando el timestamp que
/// SwiftUI le entrega, y de reportar la altura del contenido/contenedor vía
/// `actualizarAlturas(contenido:visible:)` para que el controller pueda
/// calcular el clamp de fin de texto.
@Observable
final class TeleprompterController {

    /// Texto del guion. Expuesto como `var` para que T23 lo sobreescriba
    /// con el guion persistido del usuario. Al cambiar, se reinicia el
    /// scroll (nuevo guion empieza desde arriba).
    var texto: String {
        didSet {
            guard texto != oldValue else { return }
            reiniciar()
        }
    }

    /// Posición vertical actual del scroll, en puntos. 0 = inicio.
    private(set) var posicionActualPx: Double = 0

    /// true mientras el scroll avanza automáticamente.
    private(set) var estaReproduciendo = false

    /// Multiplicador interno de velocidad (default 1.0). T22 lo controlará
    /// en vivo vía `setVelocidad(_:)` según el nivel de voz detectado.
    private(set) var factorVelocidad: Double = 1.0

    /// Fuente de la velocidad base, en px/s (de `AjustesStore`).
    private let ajustes: AjustesStore

    /// Timestamp (en segundos, reloj monotónico de `TimelineView`) del
    /// último tick procesado. `nil` mientras está pausado/sin arrancar, para
    /// que el primer tick tras `iniciar()` no aplique un delta gigante
    /// acumulado desde un timestamp viejo.
    private var ultimoTimestamp: Date?

    /// Altura real del texto renderizado (medida por la vista vía
    /// preferencia de tamaño de SwiftUI).
    private var alturaContenidoPx: Double = 0

    /// Altura visible del contenedor del overlay.
    private var alturaVisiblePx: Double = 0

    init(ajustes: AjustesStore, texto: String = guionDeEjemplo) {
        self.ajustes = ajustes
        self.texto = texto
    }

    /// Desplazamiento máximo permitido antes de que el texto se salga por
    /// completo del contenedor visible (clamp de fin).
    private var posicionMaximaPx: Double {
        max(0, alturaContenidoPx - alturaVisiblePx)
    }

    /// Llamado por la vista cuando mide el tamaño real del texto y del
    /// contenedor (p. ej. desde `.onGeometryChange` o una preferencia de
    /// tamaño). Vuelve a aplicar el clamp por si el nuevo tamaño es menor
    /// que la posición actual.
    func actualizarAlturas(contenido: Double, visible: Double) {
        alturaContenidoPx = contenido
        alturaVisiblePx = visible
        posicionActualPx = min(posicionActualPx, posicionMaximaPx)
    }

    func iniciar() {
        guard !estaReproduciendo else { return }
        estaReproduciendo = true
        // No fijamos `ultimoTimestamp` aquí: se toma en el primer `avanzar`
        // tras iniciar, para que el delta del primer frame sea ~0 en vez de
        // saltar todo el tiempo que estuvo pausado.
        ultimoTimestamp = nil
    }

    func pausar() {
        estaReproduciendo = false
        ultimoTimestamp = nil
    }

    func reiniciar() {
        posicionActualPx = 0
        ultimoTimestamp = nil
    }

    /// Reactivo en vivo: se lee directamente en cada cálculo de `avanzar`,
    /// así que cambiar la velocidad a mitad de la animación no la reinicia
    /// ni la interrumpe — solo cambia la pendiente del avance desde ese
    /// punto en adelante.
    func setVelocidad(_ factor: Double) {
        factorVelocidad = max(0, factor)
    }

    /// Debe llamarse en cada tick de `TimelineView(.animation)` con el
    /// timestamp (`context.date` o equivalente) que SwiftUI entrega. Calcula
    /// el delta de tiempo real desde el último tick y avanza la posición en
    /// proporción a ese delta — nunca un incremento fijo por llamada.
    func avanzar(hasta ahora: Date) {
        defer { ultimoTimestamp = ahora }

        guard estaReproduciendo else { return }

        guard let anterior = ultimoTimestamp else {
            // Primer tick tras iniciar/reanudar: solo establece la
            // referencia, sin avanzar (evita un salto por delta acumulado).
            return
        }

        let deltaSegundos = ahora.timeIntervalSince(anterior)
        guard deltaSegundos > 0 else { return }

        let velocidadPxPorSegundo = ajustes.velocidadBase * factorVelocidad
        let nuevaPosicion = posicionActualPx + velocidadPxPorSegundo * deltaSegundos
        posicionActualPx = min(nuevaPosicion, posicionMaximaPx)

        if posicionActualPx >= posicionMaximaPx {
            // Fin del texto: se detiene solo (clamp), sin necesidad de que
            // algo externo llame `pausar()`.
            estaReproduciendo = false
        }
    }
}
