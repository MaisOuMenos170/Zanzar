import SwiftUI

/// A short stamp press. No bounce, particles, or loop.
struct PaperStampPress: ViewModifier {
    var phase: PaperStampPhase
    var role: PaperStampRole
    var travel: CGFloat = 28

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale, anchor: .center)
            .rotationEffect(rotation)
            .offset(y: offset)
            .opacity(opacity)
    }

    private var scale: CGFloat {
        switch role {
        case .mark:
            phase == .lifted && !reduceMotion ? 1.18 : 1
        case .sheet:
            phase == .contact && !reduceMotion ? 0.98 : 1
        }
    }

    private var rotation: Angle {
        guard role == .mark, phase == .lifted, !reduceMotion else { return .zero }
        return .degrees(-8)
    }

    private var offset: CGFloat {
        guard role == .mark, phase == .lifted, !reduceMotion else { return 0 }
        return -travel
    }

    private var opacity: Double {
        guard role == .mark, phase == .lifted, !reduceMotion else { return 1 }
        return 0
    }
}

extension View {
    func paperStampPress(
        phase: PaperStampPhase,
        role: PaperStampRole,
        travel: CGFloat = 28
    ) -> some View {
        modifier(PaperStampPress(phase: phase, role: role, travel: travel))
    }
}
