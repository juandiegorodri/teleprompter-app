import SwiftUI

/// Pantalla del editor de guion (T23): un `TextEditor` donde el usuario
/// escribe/pega el guion, un botón "Guardar" que persiste el texto vía
/// `GuionStore` y lo aplica al `TeleprompterController` (que reinicia el
/// scroll solo, gracias al `didSet` de `texto` — T21), y un botón para
/// cerrar sin perder el guion ya guardado.
///
/// Al abrir, carga el texto actualmente en uso del teleprompter (que ya
/// viene inicializado con el guion guardado o el de ejemplo, según
/// `GuionStore.cargar()` en el punto de composición de la app), para que el
/// usuario vea y pueda seguir editando lo que ya está activo.
struct PantallaEditor: View {

    let teleprompter: TeleprompterController
    let guionStore: GuionStore
    let alCerrar: () -> Void

    @State private var textoEditado: String

    init(teleprompter: TeleprompterController, guionStore: GuionStore, alCerrar: @escaping () -> Void) {
        self.teleprompter = teleprompter
        self.guionStore = guionStore
        self.alCerrar = alCerrar
        _textoEditado = State(initialValue: teleprompter.texto)
    }

    var body: some View {
        NavigationStack {
            TextEditor(text: $textoEditado)
                .font(.body)
                .padding(8)
                .navigationTitle("Editar guion")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cerrar", action: alCerrar)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Guardar") {
                            guardar()
                        }
                    }
                }
        }
    }

    /// Persiste el texto bajo la clave estable de `GuionStore` (sobrescribe,
    /// no acumula) y lo aplica al teleprompter — asignar `texto` dispara su
    /// `didSet`, que reinicia el scroll automáticamente, sin que esta vista
    /// tenga que saber nada de cómo funciona el scroll.
    private func guardar() {
        guionStore.guardar(textoEditado)
        teleprompter.texto = textoEditado
        alCerrar()
    }
}

#Preview {
    PantallaEditor(
        teleprompter: TeleprompterController(ajustes: AjustesStore()),
        guionStore: GuionStore(),
        alCerrar: {}
    )
}
