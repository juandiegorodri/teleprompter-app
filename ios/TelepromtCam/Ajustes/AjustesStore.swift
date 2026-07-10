import AVFoundation
import Foundation
import Observation
import SwiftUI

/// Claves estables de `UserDefaults`, centralizadas para evitar typos entre
/// lectura y escritura (el mismo problema que en la web se resuelve con
/// constantes de `localStorage`).
private enum ClaveAjuste: String {
    case calidadCamara = "ajustes.calidadCamara"
    case fps = "ajustes.fps"
    case posicionLente = "ajustes.posicionLente"
    case tamanoFuente = "ajustes.tamanoFuente"
    case colorTextoRojo = "ajustes.colorTexto.rojo"
    case colorTextoVerde = "ajustes.colorTexto.verde"
    case colorTextoAzul = "ajustes.colorTexto.azul"
    case colorTextoAlfa = "ajustes.colorTexto.alfa"
    case opacidadFondoTexto = "ajustes.opacidadFondoTexto"
    case velocidadBase = "ajustes.velocidadBase"
}

/// Punto único de acceso y persistencia de todas las preferencias del
/// usuario (equivalente nativo del `localStorage` de la web). Ninguna otra
/// pantalla debe leer/escribir `UserDefaults` directamente: todo pasa por
/// aquí.
///
/// Cada propiedad expone un getter/setter que persiste inmediatamente en
/// `UserDefaults` bajo una clave estable de `ClaveAjuste`. Si la clave no
/// existe (primera ejecución, o instalación previa a que se agregara la
/// preferencia), `UserDefaults` devuelve `0`/`nil` según el tipo — por eso
/// cada lectura verifica explícitamente `object(forKey:) != nil` antes de
/// confiar en el valor, y si falta cae al default sin forzar unwraps.
///
/// Rangos de validación (tamaño de fuente, opacidad, velocidad) se acotan
/// aquí mismo al escribir, igual que la defensa `acotar...` de la web T15b.
@Observable
final class AjustesStore {

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Calidad de cámara

    var calidadCamara: CalidadCamara {
        get {
            guard let crudo = defaults.string(forKey: ClaveAjuste.calidadCamara.rawValue),
                let valor = CalidadCamara(rawValue: crudo)
            else {
                return .porDefecto
            }
            return valor
        }
        set {
            defaults.set(newValue.rawValue, forKey: ClaveAjuste.calidadCamara.rawValue)
        }
    }

    // MARK: - FPS

    var fps: FPS {
        get {
            guard defaults.object(forKey: ClaveAjuste.fps.rawValue) != nil else {
                return .porDefecto
            }
            let crudo = Int32(defaults.integer(forKey: ClaveAjuste.fps.rawValue))
            return FPS(rawValue: crudo) ?? .porDefecto
        }
        set {
            defaults.set(Int(newValue.rawValue), forKey: ClaveAjuste.fps.rawValue)
        }
    }

    // MARK: - Lente por defecto

    var posicionLentePorDefecto: AVCaptureDevice.Position {
        get {
            guard defaults.object(forKey: ClaveAjuste.posicionLente.rawValue) != nil else {
                return .front
            }
            let crudo = defaults.integer(forKey: ClaveAjuste.posicionLente.rawValue)
            return AVCaptureDevice.Position(rawValue: crudo) ?? .front
        }
        set {
            defaults.set(newValue.rawValue, forKey: ClaveAjuste.posicionLente.rawValue)
        }
    }

    // MARK: - Tipografía: tamaño

    /// Rango razonable de tamaño de fuente en puntos.
    static let rangoTamanoFuente: ClosedRange<Double> = 14...96
    static let tamanoFuentePorDefecto: Double = 32

    var tamanoFuente: Double {
        get {
            guard defaults.object(forKey: ClaveAjuste.tamanoFuente.rawValue) != nil else {
                return Self.tamanoFuentePorDefecto
            }
            let crudo = defaults.double(forKey: ClaveAjuste.tamanoFuente.rawValue)
            return crudo.acotado(a: Self.rangoTamanoFuente)
        }
        set {
            defaults.set(newValue.acotado(a: Self.rangoTamanoFuente), forKey: ClaveAjuste.tamanoFuente.rawValue)
        }
    }

    // MARK: - Tipografía: color de texto

    /// Componentes RGBA guardados por separado (más robusto que un hex string
    /// frente a espacios de color distintos) y reconstruibles a `Color` de
    /// SwiftUI mediante `colorTexto`.
    private static let colorTextoPorDefecto: (r: Double, g: Double, b: Double, a: Double) = (1, 1, 1, 1)

    var colorTexto: Color {
        get {
            Color(
                red: componenteColor(.colorTextoRojo, Self.colorTextoPorDefecto.r),
                green: componenteColor(.colorTextoVerde, Self.colorTextoPorDefecto.g),
                blue: componenteColor(.colorTextoAzul, Self.colorTextoPorDefecto.b),
                opacity: componenteColor(.colorTextoAlfa, Self.colorTextoPorDefecto.a)
            )
        }
        set {
            guard let componentes = newValue.resolveRGBA() else { return }
            defaults.set(componentes.r, forKey: ClaveAjuste.colorTextoRojo.rawValue)
            defaults.set(componentes.g, forKey: ClaveAjuste.colorTextoVerde.rawValue)
            defaults.set(componentes.b, forKey: ClaveAjuste.colorTextoAzul.rawValue)
            defaults.set(componentes.a, forKey: ClaveAjuste.colorTextoAlfa.rawValue)
        }
    }

    private func componenteColor(_ clave: ClaveAjuste, _ porDefecto: Double) -> Double {
        guard defaults.object(forKey: clave.rawValue) != nil else { return porDefecto }
        return defaults.double(forKey: clave.rawValue).acotado(a: 0...1)
    }

    // MARK: - Fondo del texto: opacidad

    static let opacidadFondoTextoPorDefecto: Double = 0.6

    var opacidadFondoTexto: Double {
        get {
            guard defaults.object(forKey: ClaveAjuste.opacidadFondoTexto.rawValue) != nil else {
                return Self.opacidadFondoTextoPorDefecto
            }
            return defaults.double(forKey: ClaveAjuste.opacidadFondoTexto.rawValue).acotado(a: 0...1)
        }
        set {
            defaults.set(newValue.acotado(a: 0...1), forKey: ClaveAjuste.opacidadFondoTexto.rawValue)
        }
    }

    // MARK: - Velocidad base del teleprompter

    /// Rango en px/s, igual que el slider de la web T15b (mismo default: 24).
    static let rangoVelocidadBase: ClosedRange<Double> = 12...100
    static let velocidadBasePorDefecto: Double = 24

    var velocidadBase: Double {
        get {
            guard defaults.object(forKey: ClaveAjuste.velocidadBase.rawValue) != nil else {
                return Self.velocidadBasePorDefecto
            }
            let crudo = defaults.double(forKey: ClaveAjuste.velocidadBase.rawValue)
            return crudo.acotado(a: Self.rangoVelocidadBase)
        }
        set {
            defaults.set(newValue.acotado(a: Self.rangoVelocidadBase), forKey: ClaveAjuste.velocidadBase.rawValue)
        }
    }
}

private extension Double {
    /// Acota el valor al rango dado — equivalente a la defensa
    /// `acotar...` de la web para que nunca se persista/lea un valor fuera
    /// de rango.
    func acotado(a rango: ClosedRange<Double>) -> Double {
        min(max(self, rango.lowerBound), rango.upperBound)
    }
}

private extension Color {
    /// Extrae los componentes RGBA vía `UIColor`, único puente confiable en
    /// iOS para obtener valores numéricos de un `Color` de SwiftUI.
    func resolveRGBA() -> (r: Double, g: Double, b: Double, a: Double)? {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else {
            return nil
        }
        return (Double(r), Double(g), Double(b), Double(a))
    }
}
