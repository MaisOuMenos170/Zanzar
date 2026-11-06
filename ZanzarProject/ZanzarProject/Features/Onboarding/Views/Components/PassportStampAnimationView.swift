import SwiftUI

/// Plays the passport intro once: the passport waits empty, a hand brings the LERO stamp, presses it on the
/// page. The count of collected stamps stays at 0: this stamp is the passport's welcome, not a place's stamp.
/// With Reduce Motion it shows the finished passport at once.
struct PassportStampAnimationView: View {
    let avatar: Avatar
    let name: String

    @State private var stage = PassportStampStage.idle
    @State private var phase = PaperStampPhase.settled
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
        .task {
            await play()
        }
    }

    private func play() async {
        guard stage == .idle else { return }
        if reduceMotion {
            stage = .stamped
            return
        }

        try? await Task.sleep(for: .milliseconds(700))
        guard !Task.isCancelled else { return }

        phase = .lifted
        withAnimation(.easeOut(duration: 0.45)) {
            stage = .handOver
        }
        try? await Task.sleep(for: .milliseconds(650))
        guard !Task.isCancelled else { return }

        PaperStampPhase.play(
            duration: 0.35,
            reduceMotion: false,
            update: { phase = $0 },
            onContact: {
                withAnimation(.easeOut(duration: 0.2)) {
                    stage = .stamped
                }
            }
        )
    }
}

#Preview {
    PassportStampAnimationView(avatar: .placeholder, name: "Exemplo de Nome")
        .background(Color.brandBlue50)
}
