import Foundation

/// Clave estable de `UserDefaults` para el guion persistido. Un único guion
/// (sin múltiples/títulos/nube, igual que la v1 de la web) — guardar
/// siempre sobreescribe el valor bajo esta misma clave, nunca acumula
/// copias.
private enum ClaveGuion: String {
    case guionGuardado = "editor.guion"
}

/// Persistencia del guion del teleprompter.
///
/// Elección de mecanismo: `UserDefaults`, igual patrón que `AjustesStore`
/// (T19) — mismo enfoque de clave estable centralizada en un enum privado,
/// mismo punto único de acceso. Se prefiere sobre `FileManager`/Documentos
/// porque un guion de teleprompter es texto corto/mediano (unos pocos KB a
/// lo sumo; no es un archivo grande ni binario), y `UserDefaults` ya es el
/// mecanismo de persistencia consistente en el resto del proyecto — usar
/// dos mecanismos distintos para dos tipos de preferencias simples
/// agregaría complejidad sin beneficio real. Si en el futuro el guion
/// creciera a tamaños grandes (varios MB) o se necesitara acceso desde
/// fuera de la app, `FileManager`/Documentos sería la elección correcta,
/// pero está fuera del alcance de v1.
struct GuionStore {

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Devuelve el guion guardado, o `nil` si el usuario nunca ha guardado
    /// uno (primer uso). El llamador decide el fallback (guion de ejemplo).
    func cargar() -> String? {
        defaults.string(forKey: ClaveGuion.guionGuardado.rawValue)
    }

    /// Persiste el guion, sobrescribiendo cualquier valor anterior bajo la
    /// misma clave estable (nunca acumula copias).
    func guardar(_ texto: String) {
        defaults.set(texto, forKey: ClaveGuion.guionGuardado.rawValue)
    }
}
