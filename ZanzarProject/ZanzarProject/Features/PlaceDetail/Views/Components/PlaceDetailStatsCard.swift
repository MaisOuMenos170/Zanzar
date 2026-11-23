import SwiftUI

struct PlaceDetailStatsCard: View {
    let totalCheckIns: Int
    let category: ZanzarPlaceCategory
    let hasCheckedIn: Bool
    let isInActiveItinerary: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Earned seals already on the card stay put. The slam runs only when check-in flips on screen.
    @State private var showsEarned: Bool
    /// The blank seal under the stamp, until the stamp has landed on it.
    @State private var showsPreview: Bool
    /// What the counter says. It holds the old number until the stamp lands, then rolls to the new one.
    @State private var shownCount: Int
    @State private var slamCount = 0
    @State private var isSlamming = false
    @State private var landingCount = 0
    @State private var isVisible = false
    @ScaledMetric(relativeTo: .largeTitle) private var counterSize: CGFloat = 48

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
        _showsPreview = State(initialValue: !hasCheckedIn)
        _shownCount = State(initialValue: totalCheckIns)
    }

    private var sealSize: CGFloat {
        isInActiveItinerary ? 72 : 102
    }

    var body: some View {
        AdaptiveStack(horizontalAlignment: .center, spacing: dynamicTypeSize.isAccessibilitySize ? 12 : 0) {
            VStack(spacing: 8) {
                Text(shownCount, format: .number)
                    .contentTransition(.numericText(value: Double(shownCount)))
                    .animation(reduceMotion ? nil : .default, value: shownCount)
                    .font(.system(size: counterSize, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text("placeDetail.statsCard.totalCheckInsLabel")
                    .typography(.subtitle2)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(Color.brandPurple800)
            .frame(maxWidth: .infinity)

            HStack(spacing: 12) {
                seal(label: categorySealAccessibilityLabel) { state in
                    PlaceCategorySealView(category: category, state: state, size: sealSize)
                }

                if isInActiveItinerary {
                    seal(label: itinerarySealAccessibilityLabel) { state in
                        ItineraryStampView(state: state, size: sealSize)
                    }
                }
            }
        }
        .padding(.horizontal, isInActiveItinerary ? 24 : 36)
        .padding(.vertical, 24)
        .frame(minHeight: 149)
        // The ticket of the Figma card, with its notch on the right edge.
        .background {
            Image(.checkInFeaturedBackground)
                .resizable()
        }
        .stampCardBounce(trigger: slamCount)
        .haptic(.carimbo, trigger: landingCount)
        .onAppear {
            isVisible = true
        }
        .onDisappear {
            isVisible = false
            // The slam's task is cancelled with the view: settle on the final state.
            if isSlamming {
                isSlamming = false
                showsPreview = false
                shownCount = totalCheckIns
            }
        }
        // Declared before the count's handler: both fire in one update when a check-in succeeds.
        .onChange(of: hasCheckedIn) { _, checkedIn in
            guard checkedIn, !showsEarned else { return }
            guard isVisible, !reduceMotion else {
                showsEarned = true
                showsPreview = false
                shownCount = totalCheckIns
                return
            }
            showsEarned = true
            isSlamming = true
            slamCount += 1
        }
        .onChange(of: totalCheckIns) { _, count in
            // While the stamp is coming down the counter waits for it (see `playSlam`).
            guard !isSlamming else { return }
            shownCount = count
        }
        .task(id: slamCount) {
            guard slamCount > 0 else { return }
            await playSlam()
        }
    }

    /// One seal slot: the blank preview, and above it the earned stamp that slams down on it.
    private func seal<Seal: View>(
        label: String,
        @ViewBuilder _ makeSeal: (PlaceCategorySealState) -> Seal
    ) -> some View {
        ZStack {
            makeSeal(.preview)
                .opacity(showsPreview ? 1 : 0)
            if showsEarned {
                makeSeal(.earned)
                    .stampSlam(trigger: slamCount)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }

    /// The beats of the Figma animation that are not a view effect: the blank seal goes away as the stamp lands,
    /// the haptic taps on contact, and the counter rolls to the new total just after.
    private func playSlam() async {
        let beforeContact = StampSlam.contactDelay - 0.06
        try? await Task.sleep(for: .seconds(beforeContact))
        withAnimation(.linear(duration: 0.08)) { showsPreview = false }
        try? await Task.sleep(for: .seconds(0.06))
        landingCount += 1
        try? await Task.sleep(for: .seconds(0.2))
        shownCount = totalCheckIns
        isSlamming = false
    }

    private var categoryLabel: String {
        switch category {
        case .restaurant:
            L10n.string("placeDetail.tag.restaurant")
        case .bar:
            L10n.string("placeDetail.tag.bar")
        case .cafe:
            L10n.string("placeDetail.tag.cafe")
        case .museum:
            L10n.string("placeDetail.tag.museum")
        case .park:
            L10n.string("placeDetail.tag.park")
        case .tourist:
            L10n.string("placeDetail.tag.touristSpot")
        case .historic:
            L10n.string("placeDetail.tag.historic")
        case .curiosity:
            L10n.string("placeDetail.tag.curiosity")
        case .party:
            L10n.string("placeDetail.tag.party")
        case .center:
            L10n.string("placeDetail.tag.center")
        case .unknown:
            L10n.string("placeDetail.statsCard.categoryUnknown")
        }
    }

    private var categorySealAccessibilityLabel: String {
        if hasCheckedIn {
            L10n.string("placeDetail.statsCard.sealEarnedAccessibilityLabel", categoryLabel)
        } else {
            L10n.string("placeDetail.statsCard.sealPreviewAccessibilityLabel", categoryLabel)
        }
    }

    private var itinerarySealAccessibilityLabel: String {
        hasCheckedIn
            ? L10n.string("placeDetail.statsCard.itinerarySealEarnedAccessibilityLabel")
            : L10n.string("placeDetail.statsCard.itinerarySealPreviewAccessibilityLabel")
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
