import SwiftUI
import UIKit

struct ContentView: View {
    @State private var camara = CamaraController()
    @State private var ajustes = AjustesStore()
    @State private var teleprompter: TeleprompterController
    @State private var voz: VozController
    private let guionStore = GuionStore()

    @State private var mostrandoEditor = false

    init() {
        let ajustes = AjustesStore()
        _ajustes = State(initialValue: ajustes)
        // Punto de composición del guion inicial (T23): si hay uno guardado
        // en `GuionStore` (el usuario ya guardó antes en el editor), se usa
        // ese; si no (primer uso — `cargar()` devuelve `nil`), se cae al
        // guion de ejemplo sin crashear, usando el default del
        // inicializador de `TeleprompterController`.
        let teleprompter: TeleprompterController
        if let guionGuardado = GuionStore().cargar() {
            teleprompter = TeleprompterController(ajustes: ajustes, texto: guionGuardado)
        } else {
            teleprompter = TeleprompterController(ajustes: ajustes)
        }
        _teleprompter = State(initialValue: teleprompter)
        _voz = State(initialValue: VozController(teleprompter: teleprompter))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if camara.sesionActiva {
                PreviewCamara(session: camara.session)
                    .ignoresSafeArea()
            }

            VStack {
                if camara.sesionActiva {
                    OverlayTeleprompter(ajustes: ajustes, controlador: teleprompter)
                        .padding(.horizontal, 8)
                        .onAppear {
                            teleprompter.iniciar()
                            // Mismo gesto de usuario que activó la cámara
                            // (el permiso de micrófono ya se concedió junto
                            // con el de video en `solicitarPermisosYActivar`)
                            // — arranca la detección de voz (T22) en cuanto
                            // la sesión de cámara queda activa.
                            voz.iniciar()
                        }
                        .onDisappear { voz.detener() }
                }

                Spacer()

                if let mensaje = camara.mensajeError {
                    Text(mensaje)
                        .font(.callout)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                }

                if !camara.sesionActiva {
                    Button(botonTitulo) {
                        if camara.estadoPermiso == .denegado || camara.estadoPermiso == .restringido {
                            abrirAjustes()
                        } else {
                            camara.solicitarPermisosYActivar()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.bottom, 40)

                    // Acceso al editor de guion (T23). La deshabilitación de
                    // controles secundarios hasta que la cámara esté activa
                    // (mencionada en T24) se resuelve ahí; por ahora este es
                    // el único punto de entrada a `PantallaEditor`.
                    Button("Editar guion") {
                        mostrandoEditor = true
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $mostrandoEditor) {
            PantallaEditor(teleprompter: teleprompter, guionStore: guionStore) {
                mostrandoEditor = false
            }
        }
    }

    private var botonTitulo: String {
        switch camara.estadoPermiso {
        case .denegado, .restringido:
            "Abrir Ajustes"
        case .noSolicitado, .autorizado:
            "Activar cámara"
        }
    }

    private func abrirAjustes() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    ContentView()
}
