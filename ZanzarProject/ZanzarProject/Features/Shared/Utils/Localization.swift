import Foundation

/// Localization helper that works in all contexts (SwiftUI, Models, Services, etc.)
enum L10n {
    /// Returns the localized string for the given key.
    /// Falls back to the key itself if localization fails.
    static func string(_ key: String, tableName: String? = nil, bundle: Bundle = .main, comment: String = "") -> String {
        NSLocalizedString(key, tableName: tableName, bundle: bundle, comment: comment)
    }

    /// Returns the localized string with format arguments.
    static func string(_ key: String, _ arguments: CVarArg..., tableName: String? = nil, bundle: Bundle = .main, comment: String = "") -> String {
        String(format: string(key, tableName: tableName, bundle: bundle, comment: comment), locale: Locale.current, arguments: arguments)
    }
}