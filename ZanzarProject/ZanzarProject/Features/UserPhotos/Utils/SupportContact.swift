import Foundation

/// The developer contact shown in the app (App Review guideline 1.2), from `ZANZAR_SUPPORT_EMAIL`
/// in the xcconfig via the `ZanzarSupportEmail` Info.plist key. Without one (Debug builds) it is the Lero address.
nonisolated enum SupportContact {
    static let defaultEmail = "contato@lero.social"
    /// Public privacy policy (also the URL in App Store Connect). Guideline 5.1.1 wants it reachable inside the app.
    static let privacyPolicyURL = URL(string: "https://lero.social/privacidade")!

    static var email: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "ZanzarSupportEmail") as? String else {
            return defaultEmail
        }
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        return trimmed.contains("@") ? trimmed : defaultEmail
    }

    static var mailURL: URL? {
        email.flatMap { URL(string: "mailto:\($0)") }
    }
}
