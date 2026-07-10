import SwiftUI
import UIKit

struct ContentView: View {
    @State private var camara = CamaraController()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if camara.sesionActiva {
                PreviewCamara(session: camara.session)
                    .ignoresSafeArea()
            }

            VStack {
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
