import AVFoundation
import Foundation

/// Calidad de captura de video seleccionable por el usuario, mapeada a un
/// `AVCaptureSession.Preset` de AVFoundation. `.alta` es el equivalente al
/// `.high` que `CamaraController` usa por defecto hoy (T17/T18).
enum CalidadCamara: String, CaseIterable, Codable {
    case hd720
    case hd1080
    case uhd4k
    case alta

    /// Preset de `AVCaptureSession` correspondiente. La aplicación real del
    /// preset (con `canSetSessionPreset`/`begin/commitConfiguration`) es T20.
    var preset: AVCaptureSession.Preset {
        switch self {
        case .hd720:
            return .hd1280x720
        case .hd1080:
            return .hd1920x1080
        case .uhd4k:
            return .hd4K3840x2160
        case .alta:
            return .high
        }
    }

    /// Texto legible para UI (Picker de T20).
    var label: String {
        switch self {
        case .hd720:
            return "720p HD"
        case .hd1080:
            return "1080p Full HD"
        case .uhd4k:
            return "4K Ultra HD"
        case .alta:
            return "Alta (automática)"
        }
    }

    /// Valor por defecto si no hay nada persistido en `UserDefaults`.
    static let porDefecto: CalidadCamara = .alta
}
