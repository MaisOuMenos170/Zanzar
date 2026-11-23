import SwiftUI

/// A band of light that sweeps across a skeleton again and again, so it reads as "loading" and not as an empty screen.
/// It only shows on what is drawn: the light is masked by the view itself. With Reduce Motion on, the skeleton stays
/// still.
private struct ShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion {
                    GeometryReader { proxy in
                        let width = proxy.size.width
                        LinearGradient(
                            colors: [.white.opacity(0), .white.opacity(0.6), .white.opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: width * 0.6)
                        // From just left of the view to just right of it.
                        .offset(x: phase * width * 1.2 - width * 0.1)
                    }
                    .allowsHitTesting(false)
                }
            }
            .mask(content)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    /// Makes a skeleton shine. Put it once on the whole skeleton, so the light crosses all of it together.
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}
