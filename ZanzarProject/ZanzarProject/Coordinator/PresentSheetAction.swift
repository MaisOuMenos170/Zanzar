import SwiftUI

extension EnvironmentValues {
    /// `nil` where nothing can present them (previews, tests).
    @Entry var presentSheet: ((Sheet) -> Void)?
}
