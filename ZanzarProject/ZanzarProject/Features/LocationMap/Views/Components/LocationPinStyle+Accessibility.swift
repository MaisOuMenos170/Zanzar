import SwiftUI

extension LocationPinStyle {
    /// What the pin's look says (stamp collected or not, part of the current roteiro), for VoiceOver.
    var accessibilityValue: Text {
        switch self {
        case .available: Text("locationMap.pin.available.accessibilityValue")
        case .checkedIn: Text("locationMap.pin.checkedIn.accessibilityValue")
        case .inCurrentItinerary: Text("locationMap.pin.inCurrentItinerary.accessibilityValue")
        }
    }
}
