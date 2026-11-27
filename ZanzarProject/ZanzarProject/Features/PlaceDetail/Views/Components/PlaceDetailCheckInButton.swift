import SwiftUI

struct PlaceDetailCheckInButton: View {
    let titleKey: LocalizedStringKey
    let hasCheckedIn: Bool
    let isLoading: Bool
    /// Made without a network and waiting to be sent: shown as "pending" until the server has it.
    let isPending: Bool
    let action: () -> Void
    /// Tapping the "done" capsule (to see when the check-in was made).
    let onDoneTap: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The done capsule is quiet when the place was already visited. The press runs only on the flip.
    @State private var showsDone: Bool
    @State private var phase = PaperStampPhase.settled
    @State private var landingCount = 0
    @State private var isVisible = false

    private let stampTravel: CGFloat = 8

    init(
        titleKey: LocalizedStringKey = "placeDetail.checkInButton.title",
        hasCheckedIn: Bool,
        isLoading: Bool,
        isPending: Bool = false,
        onDoneTap: (() -> Void)? = nil,
        action: @escaping () -> Void
    ) {
        self.titleKey = titleKey
        self.hasCheckedIn = hasCheckedIn
        self.isLoading = isLoading
        self.isPending = isPending
        self.onDoneTap = onDoneTap
        self.action = action
        _showsDone = State(initialValue: hasCheckedIn)
    }

    var body: some View {
        Group {
            if isPending && !showsDone {
                Label("placeDetail.checkInButton.pendingTitle", systemImage: "clock")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color("PlaceDetailCheckInDoneBackground"), in: .capsule)
                    .overlay {
                        Capsule()
                            .strokeBorder(
                                Color("PlaceDetailCheckInDoneBorder"),
                                style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                            )
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityHint(Text("placeDetail.checkInButton.pendingHint"))
            } else if showsDone {
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
                    .haptic(.carimboLeve, trigger: landingCount)
                    .contentShape(.capsule)
                    .onTapGesture { onDoneTap?() }
                    .accessibilityAddTraits(onDoneTap == nil ? .isStaticText : .isButton)
                    .accessibilityHint(Text(onDoneTap == nil ? "" : L10n.string("placeDetail.checkInButton.doneHint")))
            } else {
                Button(action: action) {
                    Text(titleKey)
                        .opacity(isLoading ? 0 : 1)
                }
                .buttonStyle(AuthPrimaryButtonStyle(background: .brandPurple500))
                .disabled(isLoading)
                .overlay {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .transition(.opacity)
                    }
                }
                .motion(Motion.suave, value: isLoading)
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
                size: .small,
                reduceMotion: reduceMotion,
                update: { phase = $0 },
                onContact: { landingCount += 1 }
            )
        }
    }
}
