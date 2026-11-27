import SwiftUI

extension EnvironmentValues {
    /// Switches the main tab bar to another tab (e.g. "Explorar o mapa" on an empty profile).
    /// `nil` where there is no tab bar (previews, tests).
    @Entry var selectTab: ((MainTab) -> Void)?
}
