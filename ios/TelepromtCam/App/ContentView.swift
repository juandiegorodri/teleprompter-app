import SwiftUI
import UIKit

struct ContentView: View {
    @State private var camara = CamaraController()
    @State private var ajustes = AjustesStore()
    @State private var teleprompter: TeleprompterController
    @State private var voz: VozController

    init() {
        let ajustes = AjustesStore()
        _ajustes = State(initialValue: ajustes)
        let teleprompter = TeleprompterController(ajustes: ajustes)
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
                }
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
