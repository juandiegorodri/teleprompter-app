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
                            // Wiring T29: `CamaraController` es el delegate del
                            // `AVCaptureAudioDataOutput` (necesita los buffers
                            // para escribir la pista de audio del
                            // `AVAssetWriter`) y le reenvía cada buffer de audio
                            // a `VozController.procesarSampleBuffer(_:)`. Aquí
                            // se conecta esa referencia (weak en CamaraController
                            // para no crear ciclo) y se activa el VAD. El
                            // permiso de micrófono ya se concedió junto con el
                            // de video en `solicitarPermisosYActivar`. El
                            // teleprompter NO arranca aquí: solo con "Grabar".
                            camara.vozController = voz
                            voz.iniciar()
                        }
                        .onDisappear { voz.detener() }
                }

                // Medidor de nivel de micrófono (T29 punto 3): barra fina que
                // muestra `voz.nivel` en tiempo real mientras la cámara está
                // activa. El RMS crudo es pequeño (~0.0–0.15), así que se
                // escala ×6 y se clampa a 1 para que sea visible. Es la
                // herramienta de observabilidad que convierte "no funciona, no
                // sé por qué" en "la barra se mueve / no se mueve" y permite
                // calibrar los umbrales contra datos reales.
                if camara.sesionActiva {
                    MedidorNivel(nivel: voz.nivel)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
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
        // si el `AVAssetWriter` terminó `finishWriting` por su cuenta (T24
        // punto 3 / T29) — ambos caminos terminan poniendo
        // `estaGrabando = false`, así que un solo `onChange` cubre los dos
        // casos sin duplicar la llamada.
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

/// Medidor de nivel de micrófono (T29 punto 3). Barra fina horizontal cuyo
/// relleno es proporcional a `voz.nivel` (RMS crudo, ~0.0–0.15) escalado ×6 y
/// clampeado a [0,1] para que el movimiento sea visible. Etiquetado
/// discretamente "Micrófono". Sirve para que el usuario VEA si el audio entra y
/// para reportar el valor real y calibrar los umbrales del VAD.
private struct MedidorNivel: View {
    let nivel: Double

    private var fraccion: Double {
        min(max(nivel * 6, 0), 1)
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "mic.fill")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.2))
                    Capsule()
                        .fill(fraccion > 0.5 ? Color.green : Color.yellow)
                        .frame(width: geo.size.width * fraccion)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.black.opacity(0.4), in: Capsule())
        .accessibilityLabel("Nivel de micrófono")
    }
}

#Preview {
    ContentView()
}
