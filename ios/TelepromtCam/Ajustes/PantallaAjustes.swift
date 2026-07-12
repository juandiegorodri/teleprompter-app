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

    /// Mensaje de éxito visible tras aplicar calidad/fps/lente (T30). Se
    /// alimenta de `camaraController.ultimaConfiguracionAplicada` (ver
    /// `.onChange` más abajo) y se auto-oculta a los ~2s con un `Task`, así el
    /// usuario SIEMPRE sabe si su cambio se procesó, sin importar si el
    /// efecto visual en el preview es perceptible (típico en el simulador).
    @State private var mensajeExito: String?

    /// Nombre legible de una posición de lente para el Picker/etiquetas.
    private func nombreLente(_ posicion: AVCaptureDevice.Position) -> String {
        switch posicion {
        case .front: return "Frontal"
        case .back: return "Trasera"
        default: return "Desconocida"
        }
    }

    var body: some View {
        // Enumeración de cámaras REALES del dispositivo (T30), no asumidas.
        // En el simulador (una sola cámara del Mac) esto devuelve una sola
        // posición, así que el Picker de lente no debe ofrecer "Trasera".
        let posicionesDisponibles = camaraController.posicionesLenteDisponibles()

        Form {
            Section("Cámara") {
                Picker("Calidad", selection: $ajustes.calidadCamara) {
                    ForEach(CalidadCamara.allCases, id: \.self) { calidad in
                        // T30: cada preset se valida con `canSetSessionPreset`
                        // contra la sesión real antes de ofrecerlo como si
                        // fuera a funcionar sin más. En el simulador el
                        // catálogo de presets soportados suele ser más
                        // limitado/distinto que en un iPhone físico — las
                        // opciones marcadas con ⚠️ probablemente NO se
                        // apliquen aquí, aunque sí lo hagan en un dispositivo
                        // real.
                        let soportada = camaraController.session.canSetSessionPreset(calidad.preset)
                        HStack {
                            Text(calidad.label)
                                .foregroundStyle(soportada ? .primary : .secondary)
                            if !soportada {
                                Spacer()
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .accessibilityLabel("No disponible en este dispositivo")
                            }
                        }
                        .tag(calidad)
                    }
                }
                .onChange(of: ajustes.calidadCamara) { _, nuevaCalidad in
                    camaraController.aplicarCalidadCamara(nuevaCalidad)
                }

                Text("En el simulador el catálogo de presets soportados puede ser distinto o más limitado que en un iPhone físico; las opciones con ⚠️ probablemente no se apliquen aquí.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Picker("Fps", selection: $ajustes.fps) {
                    ForEach(FPS.allCases, id: \.self) { fps in
                        Text(fps.label).tag(fps)
                    }
                }
                .onChange(of: ajustes.fps) { _, nuevoFPS in
                    camaraController.aplicarFPS(nuevoFPS)
                }

                // T30: el Picker de lente solo ofrece las posiciones que
                // `AVCaptureDevice.DiscoverySession` reporta como realmente
                // disponibles. Si el dispositivo solo tiene una cámara (p.
                // ej. el simulador), no tiene sentido ofrecer una opción que
                // nunca va a funcionar: se muestra deshabilitada con una nota
                // en vez de dejar que el usuario la elija y falle en
                // silencio.
                if posicionesDisponibles.count > 1 {
                    Picker("Lente", selection: $ajustes.posicionLentePorDefecto) {
                        ForEach(posicionesDisponibles, id: \.self) { posicion in
                            Text(nombreLente(posicion)).tag(posicion)
                        }
                    }
                    .onChange(of: ajustes.posicionLentePorDefecto) { _, nuevaPosicion in
                        camaraController.cambiarLente(a: nuevaPosicion)
                    }
                } else {
                    HStack {
                        Text("Lente")
                        Spacer()
                        Text(posicionesDisponibles.first.map(nombreLente) ?? "No disponible")
                            .foregroundStyle(.secondary)
                    }
                    Text("Este dispositivo solo tiene una cámara disponible.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if let mensajeExito {
                Section {
                    Label(mensajeExito, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
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
        // T30: señal de éxito. `CamaraController` solo escribía en
        // `errorGrabacion` cuando algo FALLABA; en el camino de éxito no
        // había ninguna señal, así que el usuario reportó "no sabemos si los
        // ajustes están afectando en algo, porque no lo confirma". Ahora cada
        // aplicación exitosa de calidad/fps/lente publica una descripción en
        // `ultimaConfiguracionAplicada`, y aquí se refleja en `mensajeExito`
        // por ~2s antes de desaparecer sola.
        .onChange(of: camaraController.ultimaConfiguracionAplicada) { _, nuevoMensaje in
            guard let nuevoMensaje else { return }
            mensajeExito = nuevoMensaje
            Task {
                try? await Task.sleep(for: .seconds(2))
                if mensajeExito == nuevoMensaje {
                    mensajeExito = nil
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PantallaAjustes(ajustes: AjustesStore(), camaraController: CamaraController())
    }
}
