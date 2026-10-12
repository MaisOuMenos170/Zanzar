import SwiftUI

struct ItineraryCompletedAlertView: View {
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
                    Text("placeDetail.itineraryCompletedAlert.title")
                        .font(.headline)

                    Text("placeDetail.itineraryCompletedAlert.message")
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ItineraryStampView(state: .earned, size: 120)
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
                duration: 0.62,
                reduceMotion: reduceMotion,
                update: { phase = $0 },
                onContact: { landingCount += 1 }
            )
        }
    }
}

#Preview {
    ItineraryCompletedAlertView(onAccept: {})
}
