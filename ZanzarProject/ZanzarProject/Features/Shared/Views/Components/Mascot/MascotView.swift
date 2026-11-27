import SwiftUI

/// The little faces of the app, used to give a mood to an error or an empty screen instead of a system icon.
/// They are decoration: the title and the message say everything, so VoiceOver skips the picture.
enum Mascot {
    /// Cries: something went wrong (no connection, a load that failed).
    case sad
    /// Yawns: nothing here yet.
    case sleepy

    fileprivate var imageName: String {
        switch self {
        case .sad: "CarinhaChoro"
        case .sleepy: "CarinhaBocejando"
        }
    }
}

struct MascotView: View {
    let mascot: Mascot
    /// Grows with the text size, but stays small enough to leave room for the message.
    @ScaledMetric(relativeTo: .title) private var size: CGFloat = 88

    init(_ mascot: Mascot) {
        self.mascot = mascot
    }

    var body: some View {
        Image(mascot.imageName)
            .resizable()
            .scaledToFit()
            .frame(width: min(size, 140), height: min(size, 140))
            .accessibilityHidden(true)
    }
}

/// The label slot of a `ContentUnavailableView`: the mascot above the title.
struct MascotStateLabel: View {
    let mascot: Mascot
    let title: LocalizedStringKey

    init(_ mascot: Mascot, _ title: LocalizedStringKey) {
        self.mascot = mascot
        self.title = title
    }

    var body: some View {
        VStack(spacing: 12) {
            MascotView(mascot)
            Text(title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

#Preview {
    ContentUnavailableView {
        MascotStateLabel(.sad, "Não consegui buscar seu perfil")
    } description: {
        Text("Confere sua conexão e tenta de novo.")
    } actions: {
        Button("Tentar novamente") {}
    }
}
