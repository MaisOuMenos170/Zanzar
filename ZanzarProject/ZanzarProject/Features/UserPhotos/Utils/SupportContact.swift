import Foundation

/// The developer contact shown in the app (App Review guideline 1.2), from `ZANZAR_SUPPORT_EMAIL`
/// in the xcconfig via the `ZanzarSupportEmail` Info.plist key. Without one (Debug builds) it is the Lero address.
nonisolated enum SupportContact {
    static let defaultEmail = "contato@lero.social"

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
