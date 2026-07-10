import Foundation

/// Cuadros por segundo seleccionables para la grabación. El valor crudo se
/// persiste como `Int32` porque es el tipo que espera
/// `CMTime(value:timescale:)` al construir `activeVideoMinFrameDuration`/
/// `activeVideoMaxFrameDuration` en T20 — aquí solo se define el dato.
enum FPS: Int32, CaseIterable, Codable {
    case fps24 = 24
    case fps30 = 30
    case fps60 = 60

    /// Texto legible para UI (Picker de T20).
    var label: String {
        "\(rawValue) fps"
    }

    /// Valor por defecto si no hay nada persistido en `UserDefaults`.
    static let porDefecto: FPS = .fps30
}
