import SwiftUI

#if DEBUG && targetEnvironment(simulator)
/// Approximates the system user location dot when using a fixed dev coordinate.
struct SimulatorUserLocationMarker: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.blue.opacity(0.2))
                .frame(width: 44, height: 44)

            Circle()
                .fill(.blue)
                .frame(width: 16, height: 16)
                .overlay(Circle().stroke(.white, lineWidth: 3))
        }
        .accessibilityHidden(true)
    }
}
#endif
