import SwiftUI

/// Vista que superpone el texto del teleprompter, desplazándose
/// automáticamente, sobre el preview de la cámara. Se coloca en la franja
/// superior de la pantalla (cerca del lente frontal físico) y respeta el
/// safe area para no quedar bajo el notch/isla dinámica.
///
/// El avance usa `TimelineView(.animation)`, que SwiftUI dispara en cada
/// frame de pantalla con un timestamp (`context.date`); ese timestamp se
/// pasa tal cual a `TeleprompterController.avanzar(hasta:)`, que calcula el
/// delta de tiempo real desde el tick anterior. Así el desplazamiento es
/// proporcional al tiempo transcurrido y no al número de frames — el mismo
/// patrón que `requestAnimationFrame` con delta de tiempo en la web (T5).
struct OverlayTeleprompter: View {
    @Bindable var ajustes: AjustesStore
    @Bindable var controlador: TeleprompterController

    /// Altura visible de la franja del teleprompter.
    private let alturaFranja: CGFloat = 180

    var body: some View {
        TimelineView(.animation) { contexto in
            contenido
                .onChange(of: contexto.date) { _, nuevaFecha in
                    controlador.avanzar(hasta: nuevaFecha)
                }
        }
    }

    private var contenido: some View {
        ZStack {
            Color.black.opacity(ajustes.opacidadFondoTexto)

            GeometryReader { geometriaVisible in
                Text(controlador.texto)
                    .font(.system(size: ajustes.tamanoFuente, weight: .semibold))
                    .foregroundStyle(ajustes.colorTexto)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(
                        GeometryReader { geometriaContenido in
                            Color.clear
                                .preference(
                                    key: AlturaContenidoTexto.self,
                                    value: geometriaContenido.size.height
                                )
                        }
                    )
                    .offset(y: -controlador.posicionActualPx)
                    .frame(width: geometriaVisible.size.width, height: geometriaVisible.size.height, alignment: .top)
                    .clipped()
                    .onPreferenceChange(AlturaContenidoTexto.self) { alturaContenido in
                        controlador.actualizarAlturas(
                            contenido: alturaContenido,
                            visible: geometriaVisible.size.height
                        )
                    }
                    .onAppear {
                        controlador.actualizarAlturas(
                            contenido: controlador.posicionActualPx,
                            visible: geometriaVisible.size.height
                        )
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(height: alturaFranja)
        .clipped()
    }
}

/// Preferencia de SwiftUI usada para medir la altura real del texto
/// renderizado (necesaria para el clamp de fin de scroll), evitando tener
/// que adivinar la altura a partir del tamaño de fuente y el número de
/// líneas.
private struct AlturaContenidoTexto: PreferenceKey {
    static let defaultValue: Double = 0
    static func reduce(value: inout Double, nextValue: () -> Double) {
        value = nextValue()
    }
}

#Preview {
    let ajustes = AjustesStore()
    ZStack(alignment: .top) {
        Color.gray.ignoresSafeArea()
        OverlayTeleprompter(ajustes: ajustes, controlador: TeleprompterController(ajustes: ajustes))
            .safeAreaInset(edge: .top) { Color.clear.frame(height: 0) }
    }
}
