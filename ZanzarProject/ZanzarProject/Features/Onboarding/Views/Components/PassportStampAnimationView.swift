import SwiftUI

/// The passport scene. It waits untouched until `isPlaying` turns on, then a hand brings the LERO stamp and
/// presses it on the page, and after a short pause `onFinished` is called. The count of collected stamps stays at 0:
/// this stamp is the passport's welcome, not a place's stamp. With Reduce Motion the stamped passport shows at once.
struct PassportStampAnimationView: View {
    let avatar: Avatar
    let name: String
    let isPlaying: Bool
    let onFinished: () -> Void

    @State private var stage = PassportStampStage.idle
    @State private var phase = PaperStampPhase.settled
    @State private var landingCount = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let size = PassportIllustrationView.canvasSize
            let scale = min(proxy.size.width / size.width, proxy.size.height / size.height)
            PassportIllustrationView(avatar: avatar, name: name, stage: stage, phase: phase)
                .scaleEffect(scale)
                .frame(width: size.width * scale, height: size.height * scale)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .haptic(.carimbo, trigger: landingCount)
        .task(id: isPlaying) {
            guard isPlaying else { return }
            await play()
            // Leaving the screen cancels the task, and then the flow must not move on by itself.
            guard !Task.isCancelled else { return }
            onFinished()
        }
    }

    private func play() async {
        guard stage == .idle else { return }
        if reduceMotion {
            stage = .stamped
            try? await Task.sleep(for: .milliseconds(900))
            return
        }

        phase = .lifted
        withAnimation(.easeOut(duration: 0.45)) {
            stage = .handOver
        }
        try? await Task.sleep(for: .milliseconds(650))
        guard !Task.isCancelled else { return }

        PaperStampPhase.play(
            size: .small,
            reduceMotion: false,
            update: { phase = $0 },
            onContact: {
                landingCount += 1
                withAnimation(.easeOut(duration: 0.2)) {
                    stage = .stamped
                }
            }
        )
        try? await Task.sleep(for: .milliseconds(1400))
    }
}

#Preview {
    @Previewable @State var isPlaying = false
    VStack {
        PassportStampAnimationView(avatar: .placeholder, name: "Exemplo de Nome", isPlaying: isPlaying) {}
        Button("Play") { isPlaying = true }
    }
    .background(Color.brandBlue50)
}
