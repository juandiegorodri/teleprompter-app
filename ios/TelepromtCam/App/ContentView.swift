import SwiftUI
import UIKit

struct ContentView: View {
    @State private var camara = CamaraController()
    @State private var ajustes = AjustesStore()
    @State private var teleprompter: TeleprompterController
    @State private var voz: VozController
    private let guionStore = GuionStore()

    @State private var mostrandoEditor = false
    @State private var mostrandoAjustes = false

    /// Punto de brillo/glow del indicador de grabación (T24, punto 4):
    /// alterna con `.repeatForever` mientras `camara.estaGrabando` es
    /// `true`. Se resetea a `true` cada vez que arranca una grabación para
    /// que el titileo siempre empiece visible, no a mitad de un ciclo de
    /// baja opacidad.
    @State private var indicadorGrabacionVisible = true

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

    /// La cámara "está lista" para habilitar el resto de la UI cuando el
    /// permiso quedó autorizado Y la sesión de captura está corriendo de
    /// verdad (T24, punto 2) — no basta con el permiso, porque la sesión
    /// arranca async en `colaSesion`.
    private var camaraLista: Bool {
        camara.estadoPermiso == .autorizado && camara.sesionActiva
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
                            // Mismo gesto de usuario que activó la cámara
                            // (el permiso de micrófono ya se concedió junto
                            // con el de video en `solicitarPermisosYActivar`)
                            // — arranca la detección de voz (T22) en cuanto
                            // la sesión de cámara queda activa. El
                            // teleprompter YA NO arranca aquí (T24, punto 3):
                            // solo se mueve cuando se toca "Grabar".
                            voz.iniciar()
                        }
                        .onDisappear { voz.detener() }
                }

                Spacer()

                // Indicador de "grabando" (T24, punto 4): condicionado
                // estrictamente con `if camara.estaGrabando` — no con un
                // color/opacidad de contenedor siempre presente, evitando el
                // bug de la web (T15a) donde un `display` de alta
                // especificidad ignoraba el estado "oculto". Si
                // `estaGrabando` es `false`, esta vista NO EXISTE en el
                // árbol, punto.
                if camara.estaGrabando {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(.red)
                            .frame(width: 14, height: 14)
                            .shadow(color: .red, radius: indicadorGrabacionVisible ? 8 : 2)
                            .opacity(indicadorGrabacionVisible ? 1 : 0.25)
                        Text("Grabando")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.6), in: Capsule())
                    .padding(.bottom, 12)
                    .onAppear {
                        indicadorGrabacionVisible = true
                        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                            indicadorGrabacionVisible = false
                        }
                    }
                }

                if let mensaje = camara.mensajeError {
                    Text(mensaje)
                        .font(.callout)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                }

                if let errorGrabacion = camara.errorGrabacion {
                    Text(errorGrabacion)
                        .font(.callout)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                }

                // Controles secundarios (T24, punto 2): arrancan
                // deshabilitados y solo se habilitan cuando `camaraLista`.
                HStack(spacing: 24) {
                    Button {
                        mostrandoAjustes = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                    }
                    .disabled(!camaraLista)

                    Button {
                        mostrandoEditor = true
                    } label: {
                        Image(systemName: "text.alignleft")
                            .font(.title2)
                    }
                    .disabled(!camaraLista)
                }
                .buttonStyle(.bordered)
                .tint(.white)
                .padding(.bottom, 16)
                .opacity(camara.sesionActiva ? 1 : 0.4)

                // Botón principal grande (T24, punto 1): "Activar cámara"
                // hasta que la cámara arranca con éxito; después se oculta y
                // aparece el botón grande de Grabar/Detener.
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
                } else {
                    Button {
                        if camara.estaGrabando {
                            camara.detenerGrabacion()
                        } else {
                            camara.iniciarGrabacion()
                            teleprompter.iniciar()
                        }
                    } label: {
                        Text(camara.estaGrabando ? "Detener" : "Grabar")
                            .font(.title2.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(camara.estaGrabando ? .red : .accentColor)
                    .controlSize(.large)
                    .disabled(!camaraLista)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
        // El teleprompter se pausa tanto si el usuario tocó "Detener" como
        // si el delegate de `AVCaptureFileOutputRecordingDelegate` completó
        // la grabación por su cuenta (T24, punto 3) — ambos caminos
        // terminan poniendo `estaGrabando = false`, así que un solo
        // `onChange` cubre los dos casos sin duplicar la llamada.
        .onChange(of: camara.estaGrabando) { _, estaGrabandoAhora in
            if !estaGrabandoAhora {
                teleprompter.pausar()
            }
        }
        .sheet(isPresented: $mostrandoEditor) {
            PantallaEditor(teleprompter: teleprompter, guionStore: guionStore) {
                mostrandoEditor = false
            }
        }
        .sheet(isPresented: $mostrandoAjustes) {
            NavigationStack {
                PantallaAjustes(ajustes: ajustes, camaraController: camara)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cerrar") { mostrandoAjustes = false }
                        }
                    }
            }
        }
        // Modal obligatorio de resultado (T24, punto 5): `.fullScreenCover`
        // (NUNCA `.sheet`, que permite swipe-to-dismiss), condicionado a que
        // haya una URL de última grabación. La única forma de cerrarlo es
        // que `ModalResultado` limpie `camara.ultimaGrabacionURL` desde uno
        // de sus dos botones.
        .fullScreenCover(isPresented: mostrandoResultado) {
            if let url = camara.ultimaGrabacionURL {
                ModalResultado(url: url, camaraController: camara)
            }
        }
    }

    /// Binding derivado de `camara.ultimaGrabacionURL` para el
    /// `.fullScreenCover`: se presenta cuando hay una URL, y el único modo
    /// de que pase a `false` es que algo limpie esa URL a `nil` (lo hacen
    /// los dos botones de `ModalResultado`, nunca un gesto del sistema).
    private var mostrandoResultado: Binding<Bool> {
        Binding(
            get: { camara.ultimaGrabacionURL != nil },
            set: { nuevoValor in
                if !nuevoValor {
                    camara.limpiarUltimaGrabacion()
                }
            }
        )
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
