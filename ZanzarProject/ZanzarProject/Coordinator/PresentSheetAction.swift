import SwiftUI

extension EnvironmentValues {
    /// Presents one of the cards the tab bar's root draws over every tab ("suggest a place", "edit name").
    /// `nil` where nothing can present them (previews, tests).
    @Entry var presentSheet: ((Sheet) -> Void)?
}
