import SwiftUI

extension EnvironmentValues {
    /// Opens the "suggest a place" card, which the tab bar's root draws over every tab.
    /// `nil` where nothing can present it (previews, tests).
    @Entry var suggestPlace: (() -> Void)?
}
