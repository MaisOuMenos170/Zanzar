import Foundation

/// The developer contact shown in the app (App Review guideline 1.2), from `ZANZAR_SUPPORT_EMAIL`
/// in the xcconfig via the `ZanzarSupportEmail` Info.plist key. `nil` while it is not configured.
nonisolated enum SupportContact {
    static var email: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "ZanzarSupportEmail") as? String else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        return trimmed.contains("@") ? trimmed : nil
    }

    static var mailURL: URL? {
        email.flatMap { URL(string: "mailto:\($0)") }
    }
}
