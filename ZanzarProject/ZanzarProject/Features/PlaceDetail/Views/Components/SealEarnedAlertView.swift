import SwiftUI

struct SealEarnedAlertView: View {
    let placeName: String
    let category: ZanzarPlaceCategory
    let onAccept: () -> Void

    @AccessibilityFocusState private var isAcceptFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase = PaperStampPhase.lifted
    @State private var landingCount = 0
    @State private var didPlayStamp = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .contentShape(.rect)
                .accessibilityHidden(true)

            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("placeDetail.sealEarnedAlert.title")
                        .font(.headline)

                    Text(message)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                PlaceCategorySealView(category: category, state: .earned, size: 120)
                    .paperStampPress(phase: phase, role: .mark)

                Button("placeDetail.sealEarnedAlert.acceptButton.title", action: onAccept)
                    .buttonStyle(.glassProminent)
                    .tint(Color("RatingPromptPrimary"))
                    .controlSize(.large)
                    .buttonBorderShape(.capsule)
                    .frame(maxWidth: .infinity)
                    .accessibilityFocused($isAcceptFocused)
            }
            .padding(14)
            .frame(width: 300)
            .glassEffect(.regular, in: .rect(cornerRadius: 34))
            .paperStampPress(phase: phase, role: .sheet)
            .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.7), trigger: landingCount)
        }
        .accessibilityAddTraits(.isModal)
        .onAppear {
            isAcceptFocused = true
            guard !didPlayStamp else { return }
            didPlayStamp = true
            PaperStampPhase.play(
                duration: 0.45,
                reduceMotion: reduceMotion,
                update: { phase = $0 },
                onContact: { landingCount += 1 }
            )
        }
    }

    private var message: AttributedString {
        var name = AttributedString(placeName)
        name.inlinePresentationIntent = .stronglyEmphasized
        return AttributedString(localized: "placeDetail.sealEarnedAlert.message.prefix")
            + name
            + AttributedString(localized: "placeDetail.sealEarnedAlert.message.suffix")
    }
}

#Preview {
    SealEarnedAlertView(placeName: "Bar do Zé", category: .bar, onAccept: {})
}
