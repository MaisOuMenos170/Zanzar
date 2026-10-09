import SwiftUI

struct PlaceDetailStatsCard: View {
    let totalCheckIns: Int
    let category: ZanzarPlaceCategory
    let hasCheckedIn: Bool
    let isInActiveItinerary: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Earned seals already on the card stay put. The press runs only when check-in flips on screen.
    @State private var showsEarned: Bool
    @State private var phase = PaperStampPhase.settled
    @State private var landingCount = 0
    @State private var isVisible = false

    private let stampTravel: CGFloat = 14
    private let stampDuration: TimeInterval = 0.35

    init(
        totalCheckIns: Int,
        category: ZanzarPlaceCategory,
        hasCheckedIn: Bool,
        isInActiveItinerary: Bool
    ) {
        self.totalCheckIns = totalCheckIns
        self.category = category
        self.hasCheckedIn = hasCheckedIn
        self.isInActiveItinerary = isInActiveItinerary
        _showsEarned = State(initialValue: hasCheckedIn)
    }

    private var sealState: PlaceCategorySealState {
        showsEarned ? .earned : .preview
    }

    private var sealSize: CGFloat {
        isInActiveItinerary ? 72 : 102
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text(totalCheckIns, format: .number)
                    .contentTransition(.numericText(value: Double(totalCheckIns)))
                    .animation(reduceMotion ? nil : .default, value: totalCheckIns)
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text("placeDetail.statsCard.totalCheckInsLabel")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 12) {
                PlaceCategorySealView(category: category, state: sealState, size: sealSize)
                    .paperStampPress(phase: phase, role: .mark, travel: stampTravel)
                    .accessibilityLabel(categorySealAccessibilityLabel)

                if isInActiveItinerary {
                    ItineraryStampView(state: sealState, size: sealSize)
                        .paperStampPress(phase: phase, role: .mark, travel: stampTravel)
                        .accessibilityLabel(itinerarySealAccessibilityLabel)
                }
            }
        }
        .padding(.horizontal, isInActiveItinerary ? 24 : 36)
        .padding(.vertical, 16)
        .background(Color("PlaceDetailStatsBackground"), in: .rect(cornerRadius: 16))
        .paperStampPress(phase: phase, role: .sheet, travel: stampTravel)
        .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.7), trigger: landingCount)
        .onAppear {
            isVisible = true
        }
        .onDisappear {
            isVisible = false
        }
        .onChange(of: hasCheckedIn) { _, checkedIn in
            guard checkedIn, !showsEarned else { return }
            guard isVisible, !reduceMotion else {
                showsEarned = true
                phase = .settled
                return
            }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                phase = .lifted
                showsEarned = true
            }
        }
        .onChange(of: showsEarned) { _, earned in
            guard earned, phase == .lifted else { return }
            PaperStampPhase.play(
                duration: stampDuration,
                reduceMotion: reduceMotion,
                update: { phase = $0 },
                onContact: { landingCount += 1 }
            )
        }
    }

    private var categoryLabel: String {
        switch category {
        case .restaurant:
            String(localized: "placeDetail.tag.restaurant")
        case .bar:
            String(localized: "placeDetail.tag.bar")
        case .cafe:
            String(localized: "placeDetail.tag.cafe")
        case .museum:
            String(localized: "placeDetail.tag.museum")
        case .park:
            String(localized: "placeDetail.tag.park")
        case .tourist:
            String(localized: "placeDetail.tag.touristSpot")
        case .historic:
            String(localized: "placeDetail.tag.historic")
        case .curiosity:
            String(localized: "placeDetail.tag.curiosity")
        case .party:
            String(localized: "placeDetail.tag.party")
        case .unknown:
            String(localized: "placeDetail.statsCard.categoryUnknown")
        }
    }

    private var categorySealAccessibilityLabel: String {
        if hasCheckedIn {
            String(format: String(localized: "placeDetail.statsCard.sealEarnedAccessibilityLabel"), categoryLabel)
        } else {
            String(format: String(localized: "placeDetail.statsCard.sealPreviewAccessibilityLabel"), categoryLabel)
        }
    }

    private var itinerarySealAccessibilityLabel: String {
        hasCheckedIn
            ? String(localized: "placeDetail.statsCard.itinerarySealEarnedAccessibilityLabel")
            : String(localized: "placeDetail.statsCard.itinerarySealPreviewAccessibilityLabel")
    }
}

#Preview("Before check-in") {
    PlaceDetailStatsCard(
        totalCheckIns: 42,
        category: .restaurant,
        hasCheckedIn: false,
        isInActiveItinerary: false
    )
    .padding()
}

#Preview("In active itinerary") {
    PlaceDetailStatsCard(
        totalCheckIns: 42,
        category: .restaurant,
        hasCheckedIn: false,
        isInActiveItinerary: true
    )
    .padding()
}

#Preview("After check-in in itinerary") {
    PlaceDetailStatsCard(
        totalCheckIns: 43,
        category: .restaurant,
        hasCheckedIn: true,
        isInActiveItinerary: true
    )
    .padding()
}
