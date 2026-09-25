import Foundation

enum AppLanguage: String, CaseIterable {
    case portuguese = "pt-BR"
    case english = "en"

    var locale: Locale {
        Locale(identifier: rawValue)
    }
}

enum AppLanguageSettings {
    static let preferenceKey = "app.preferredLanguage"

    static var current: AppLanguage {
        guard let raw = UserDefaults.standard.string(forKey: preferenceKey),
              let language = AppLanguage(rawValue: raw) else {
            return .portuguese
        }
        return language
    }

    static func applyPreferredLanguageOnLaunch() {
        apply(current)
    }

    static func setLanguage(_ language: AppLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: preferenceKey)
        apply(language)
    }

    private static func apply(_ language: AppLanguage) {
        UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
    }
}
