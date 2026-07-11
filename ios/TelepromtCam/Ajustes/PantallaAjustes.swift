import AVFoundation
import SwiftUI

/// Pantalla de ajustes: calidad de cámara, fps, lente, tipografía, opacidad
/// de fondo y velocidad base, con preview en vivo (`PreviewAjustes`) y
/// aplicación en caliente a la sesión de cámara activa (`CamaraController`)
/// cuando corresponde.
///
/// Los valores de tipografía/opacidad/velocidad se leen/escriben
/// directamente sobre `AjustesStore` (que ya persiste solas, T19). Los de
/// calidad/fps/lente además disparan una llamada a `CamaraController` para
/// aplicarse en caliente si la sesión ya está activa; si la sesión no está
/// corriendo, la próxima vez que se configure usará el valor persistido
/// (a través de `AjustesStore`) — la aplicación inmediata aquí es solo para
/// cuando el usuario cambia ajustes con la cámara ya encendida.
struct PantallaAjustes: View {

    @Bindable var ajustes: AjustesStore
    let camaraController: CamaraController

    var body: some View {
        Form {
            Section("Cámara") {
                Picker("Calidad", selection: $ajustes.calidadCamara) {
                    ForEach(CalidadCamara.allCases, id: \.self) { calidad in
                        Text(calidad.label).tag(calidad)
                    }
                }
                .onChange(of: ajustes.calidadCamara) { _, nuevaCalidad in
                    camaraController.aplicarCalidadCamara(nuevaCalidad)
                }

                Picker("Fps", selection: $ajustes.fps) {
                    ForEach(FPS.allCases, id: \.self) { fps in
                        Text(fps.label).tag(fps)
                    }
                }
                .onChange(of: ajustes.fps) { _, nuevoFPS in
                    camaraController.aplicarFPS(nuevoFPS)
                }

                Picker("Lente", selection: $ajustes.posicionLentePorDefecto) {
                    Text("Frontal").tag(AVCaptureDevice.Position.front)
                    Text("Trasera").tag(AVCaptureDevice.Position.back)
                }
                .onChange(of: ajustes.posicionLentePorDefecto) { _, nuevaPosicion in
                    camaraController.cambiarLente(a: nuevaPosicion)
                }
            }

            Section {
                PreviewAjustes(ajustes: ajustes)
                    .listRowInsets(EdgeInsets())
                    .padding()
            }

            Section("Tipografía") {
                VStack(alignment: .leading) {
                    Text("Tamaño de fuente: \(Int(ajustes.tamanoFuente)) pt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(
                        value: $ajustes.tamanoFuente,
                        in: AjustesStore.rangoTamanoFuente
                    )
                }

                ColorPicker("Color del texto", selection: $ajustes.colorTexto)
            }

            Section("Fondo del texto") {
                VStack(alignment: .leading) {
                    Text("Opacidad: \(Int(ajustes.opacidadFondoTexto * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $ajustes.opacidadFondoTexto, in: 0...1)
                }
            }

            Section("Velocidad") {
                VStack(alignment: .leading) {
                    Text("Velocidad base: \(Int(ajustes.velocidadBase)) px/s")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(
                        value: $ajustes.velocidadBase,
                        in: AjustesStore.rangoVelocidadBase
                    )
                }
            }

            if let errorGrabacion = camaraController.errorGrabacion {
                Section {
                    Text(errorGrabacion)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Ajustes")
    }
}

#Preview {
    NavigationStack {
        PantallaAjustes(ajustes: AjustesStore(), camaraController: CamaraController())
    }
}
