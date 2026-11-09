import SwiftUI

extension Color {
    /// Parses `#RRGGBB`; returns `nil` for anything else.
    init?(hex: String) {
        guard hex.count == 7, hex.hasPrefix("#"), let value = UInt32(hex.dropFirst(), radix: 16) else {
            return nil
        }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

extension Color {
    var hexString: String {
        let resolved = resolve(in: EnvironmentValues())
        func component(_ value: Float) -> Int {
            Int((min(max(value, 0), 1) * 255).rounded())
        }
        let red = component(resolved.red)
        let green = component(resolved.green)
        let blue = component(resolved.blue)
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
