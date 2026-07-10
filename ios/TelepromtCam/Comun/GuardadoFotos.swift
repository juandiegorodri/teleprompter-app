import Foundation
import Photos

/// Resultado legible de un intento de guardado en Fotos, para que la UI
/// muestre un mensaje claro sin necesidad de interpretar errores de
/// `PHPhotoLibrary` directamente.
enum ResultadoGuardadoFotos {
    case exito
    case permisoDenegado
    case error(String)
}

/// Guarda un video en el carrete de Fotos usando `PHPhotoLibrary`, pidiendo
/// autorización (`.addOnly`, alineado con `NSPhotoLibraryAddUsageDescription`
/// de T16) si aún no se ha determinado. No crashea en ningún camino: permiso
/// denegado o error de guardado terminan en un `ResultadoGuardadoFotos`
/// legible para la UI.
enum GuardadoFotos {

    static func guardarVideo(en url: URL) async -> ResultadoGuardadoFotos {
        let estadoActual = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        let estadoFinal: PHAuthorizationStatus
        if estadoActual == .notDetermined {
            estadoFinal = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        } else {
            estadoFinal = estadoActual
        }

        guard estadoFinal == .authorized || estadoFinal == .limited else {
            return .permisoDenegado
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }
            return .exito
        } catch {
            return .error("No fue posible guardar el video en Fotos: \(error.localizedDescription)")
        }
    }
}
