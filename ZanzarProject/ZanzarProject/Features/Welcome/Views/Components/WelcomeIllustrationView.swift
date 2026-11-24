import SwiftUI

/// The animated artwork of the welcome screen. One clock drives the whole loop; the canvas of the design
/// is scaled to fit and sits at the bottom, where the planet meets the buttons.
struct WelcomeIllustrationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var start = Date()

    var body: some View {
        GeometryReader { proxy in
            let canvas = WelcomeArt.canvas
            let scale = min(proxy.size.width / canvas.width, proxy.size.height / canvas.height)
            // With Reduce Motion the clock stops on a finished pose; it also stops while the app is away.
            TimelineView(.animation(paused: reduceMotion || scenePhase != .active)) { context in
                WelcomeCanvasView(time: reduceMotion ? WelcomeTracks.stillTime : context.date.timeIntervalSince(start))
                    .scaleEffect(scale, anchor: .topLeading)
                    .frame(width: canvas.width * scale, height: canvas.height * scale, alignment: .topLeading)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    WelcomeIllustrationView()
        .background(Color.brandBlue50)
}
