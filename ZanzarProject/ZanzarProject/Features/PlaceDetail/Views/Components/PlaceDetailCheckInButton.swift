import SwiftUI

struct PlaceDetailCheckInButton: View {
    let hasCheckedIn: Bool
    let isLoading: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The done capsule is quiet when the place was already visited. The press runs only on the flip.
    @State private var showsDone: Bool
    @State private var phase = PaperStampPhase.settled
    @State private var landingCount = 0
    @State private var isVisible = false

    private let stampTravel: CGFloat = 8
    private let stampDuration: TimeInterval = 0.35

    init(hasCheckedIn: Bool, isLoading: Bool, action: @escaping () -> Void) {
        self.hasCheckedIn = hasCheckedIn
        self.isLoading = isLoading
        self.action = action
        _showsDone = State(initialValue: hasCheckedIn)
    }

    var body: some View {
        Group {
            if showsDone {
                Text("placeDetail.checkInButton.doneTitle")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .paperStampPress(phase: phase, role: .mark, travel: stampTravel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color("PlaceDetailCheckInDoneBackground"), in: .capsule)
                    .overlay {
                        Capsule()
                            .strokeBorder(Color("PlaceDetailCheckInDoneBorder"), lineWidth: 1)
                    }
                    .paperStampPress(phase: phase, role: .sheet, travel: stampTravel)
                    .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.55), trigger: landingCount)
                    .accessibilityAddTraits(.isStaticText)
            } else {
                Button("placeDetail.checkInButton.title", action: action)
                    .buttonStyle(AuthPrimaryButtonStyle())
                    .disabled(isLoading)
                    .overlay {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                    }
            }
        }
        .onAppear {
            isVisible = true
        }
        .onDisappear {
            isVisible = false
        }
        .onChange(of: hasCheckedIn) { _, checkedIn in
            guard checkedIn, !showsDone else { return }
            guard isVisible, !reduceMotion else {
                showsDone = true
                phase = .settled
                return
            }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                phase = .lifted
                showsDone = true
            }
        }
        .onChange(of: showsDone) { _, done in
            guard done, phase == .lifted else { return }
            PaperStampPhase.play(
                duration: stampDuration,
                reduceMotion: reduceMotion,
                update: { phase = $0 },
                onContact: { landingCount += 1 }
            )
        }
    }
}
