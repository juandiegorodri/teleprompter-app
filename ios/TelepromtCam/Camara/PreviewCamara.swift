import AVFoundation
import SwiftUI
import UIKit

/// Envuelve una `AVCaptureVideoPreviewLayer` conectada a la `AVCaptureSession`
/// de `CamaraController` para mostrar el stream de video en vivo dentro de
/// SwiftUI. `videoGravity = .resizeAspectFill` es el equivalente nativo de
/// `object-fit: cover` en la web.
struct PreviewCamara: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> VistaPreviewCamara {
        let vista = VistaPreviewCamara()
        vista.videoPreviewLayer.session = session
        vista.videoPreviewLayer.videoGravity = .resizeAspectFill
        return vista
    }

    func updateUIView(_ uiView: VistaPreviewCamara, context: Context) {
        if uiView.videoPreviewLayer.session !== session {
            uiView.videoPreviewLayer.session = session
        }
    }
}

/// `UIView` cuyo `layer` principal es una `AVCaptureVideoPreviewLayer`, para
/// que el layer se redimensione automáticamente con la vista.
final class VistaPreviewCamara: UIView {
    override static var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        // swiftlint:disable:next force_cast
        layer as! AVCaptureVideoPreviewLayer
    }
}
