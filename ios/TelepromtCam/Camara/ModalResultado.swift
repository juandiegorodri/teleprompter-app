import AVKit
import SwiftUI

/// Modal obligatorio mostrado tras terminar una grabación (T24, punto 5).
///
/// Presentado con `.fullScreenCover` (NUNCA `.sheet`) desde `ContentView`
/// para que NO tenga swipe-to-dismiss: la única forma de cerrarlo es tocando
/// uno de los dos botones de abajo. No se agrega gesto de swipe, botón de
/// cerrar ni tap-fuera — a propósito, es parte de la Definición de Hecho.
struct ModalResultado: View {

    let url: URL
    let camaraController: CamaraController

    @State private var guardando = false
    @State private var mensajeError: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                VideoPlayer(player: AVPlayer(url: url))
                    .ignoresSafeArea(edges: .top)

                if let mensajeError {
                    Text(mensajeError)
                        .font(.callout)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                HStack(spacing: 16) {
                    Button("Descartar y grabar de nuevo") {
                        descartar()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(guardando)

                    Button {
                        Task { await guardarEnFotos() }
                    } label: {
                        if guardando {
                            ProgressView()
                        } else {
                            Text("Guardar en Fotos")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(guardando)
                }
                .controlSize(.large)
                .padding()
                .background(.black.opacity(0.8))
            }
        }
        // Sin `.interactiveDismissDisabled` porque `.fullScreenCover` ya no
        // tiene swipe-to-dismiss por defecto (a diferencia de `.sheet`) — no
        // hace falta nada extra para bloquear el cierre por gesto.
    }

    /// Guarda el video en Fotos (pidiendo permiso si hace falta) y, tras
    /// terminar (con éxito o no), deja la app lista para grabar de nuevo:
    /// limpia `ultimaGrabacionURL` para cerrar el `.fullScreenCover`.
    private func guardarEnFotos() async {
        guardando = true
        let resultado = await GuardadoFotos.guardarVideo(en: url)
        guardando = false

        switch resultado {
        case .exito:
            camaraController.limpiarUltimaGrabacion()
        case .permisoDenegado:
            mensajeError = "TelepromtCam no tiene permiso para guardar en Fotos. Ve a Ajustes > Privacidad > Fotos para habilitarlo."
        case .error(let texto):
            mensajeError = texto
        }
    }

    /// Borra el archivo temporal (ignora el error si ya no existe) y limpia
    /// `ultimaGrabacionURL`, dejando la app lista para regrabar sin
    /// necesidad de reiniciar nada.
    private func descartar() {
        try? FileManager.default.removeItem(at: url)
        camaraController.limpiarUltimaGrabacion()
    }
}
