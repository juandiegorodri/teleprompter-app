import SwiftUI

/// Preview en vivo, autocontenido, de las preferencias de tipografía/color/
/// opacidad/velocidad de `AjustesStore`. Deliberadamente AISLADO del
/// teleprompter real (T21, que aún no existe) y de la superposición sobre la
/// cámara: es un texto de muestra corto dentro de un contenedor de altura
/// fija, animado con su propio loop, sin dependencias de T21/T24.
struct PreviewAjustes: View {

    let ajustes: AjustesStore

    /// Texto corto de muestra, independiente del contenido real del
    /// teleprompter (que vive en otro módulo, T21).
    private let textoDeMuestra = "Este es un ejemplo de cómo se verá tu texto en el teleprompter."

    /// Altura fija del contenedor de preview.
    private let alturaContenedor: CGFloat = 140

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vista previa")
                .font(.caption)
                .foregroundStyle(.secondary)

            GeometryReader { geometria in
                ZStack {
                    Color.black.opacity(ajustes.opacidadFondoTexto)

                    TimelineView(.animation) { contexto in
                        let desplazamiento = desplazamientoActual(
                            fecha: contexto.date,
                            anchoContenedor: geometria.size.width
                        )

                        Text(textoDeMuestra)
                            .font(.system(size: ajustes.tamanoFuente))
                            .foregroundStyle(ajustes.colorTexto)
                            .fixedSize()
                            .offset(y: desplazamiento)
                            .frame(width: geometria.size.width, height: geometria.size.height, alignment: .top)
                            .clipped()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(height: alturaContenedor)
        }
    }

    /// Calcula el desplazamiento vertical del texto de muestra en función
    /// del tiempo transcurrido y de `velocidadBase` (px/s), reiniciando en
    /// loop una vez que el texto sale por completo del contenedor. No usa
    /// `Timer` explícito: `TimelineView(.animation)` reevalúa este cálculo en
    /// cada frame, lo que basta para un preview corto y autocontenido.
    private func desplazamientoActual(fecha: Date, anchoContenedor: CGFloat) -> CGFloat {
        // Distancia total de un ciclo: la altura del contenedor más un
        // margen para que el texto entre y salga por completo antes de
        // reiniciar.
        let distanciaCiclo: CGFloat = alturaContenedor + 80
        let velocidad = max(ajustes.velocidadBase, 1)
        let duracionCiclo = Double(distanciaCiclo) / velocidad

        let tiempoTranscurrido = fecha.timeIntervalSinceReferenceDate
        let fraccion = (tiempoTranscurrido.truncatingRemainder(dividingBy: duracionCiclo)) / duracionCiclo

        // Arranca fuera de la parte inferior del contenedor y termina fuera
        // por arriba, en loop continuo.
        let inicio: CGFloat = alturaContenedor
        let fin: CGFloat = -80
        return inicio + (fin - inicio) * CGFloat(fraccion)
    }
}

#Preview {
    PreviewAjustes(ajustes: AjustesStore())
        .padding()
}
