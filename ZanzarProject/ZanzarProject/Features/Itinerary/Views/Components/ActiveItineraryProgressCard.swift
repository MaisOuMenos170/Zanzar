import SwiftUI

struct ActiveItineraryProgressCard: View {
    let activeItinerary: ActiveItinerary
    var nextStopDistance: String?
    let onContinue: () -> Void

    @State private var avatarModel = AvatarViewModel()
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var progress: ActiveItineraryProgress {
        ActiveItineraryProgress(activeItinerary)
    }

    private var showsRoute: Bool {
        !dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            topRow
                .padding(.horizontal, 10)
                .padding(.top, 10)

            Text(activeItinerary.name)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(Color.brandSheetTitle)
                .frame(maxWidth: 200, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 16)
                .padding(.top, 15)

            Spacer(minLength: 16)

            bottomRow
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: ActiveItineraryRouteGeometry.height)
        .background {
            ZStack {
                Self.base
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.2), location: 0.0209),
                        .init(color: Self.warmTint.opacity(0.2), location: 0.9499)
                    ],
                    startPoint: UnitPoint(x: 1.045, y: 0.219),
                    endPoint: UnitPoint(x: -0.045, y: 0.78)
                )
                if showsRoute {
                    ActiveItineraryRouteView(progress: progress, avatar: avatarModel.avatar ?? .placeholder)
                        .frame(maxHeight: .infinity, alignment: .top)
                }
            }
        }
        .clipShape(.rect(cornerRadius: 16))
        .accessibilityElement(children: .contain)
        .task { await avatarModel.load() }
    }

    private var topRow: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("itinerary.activeCard.status")
                .font(.caption2)
                .foregroundStyle(Color.brandNeutral600)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white, in: .capsule)
                .overlay { Capsule().strokeBorder(Color.brandNeutral200, lineWidth: 1) }

            Spacer(minLength: 0)

            Text("itinerary.activeCard.progress \(progress.currentNumber) \(progress.total)")
                .font(.caption2.bold())
                .foregroundStyle(Color.brandPurple600)
        }
    }

    private var bottomRow: some View {
        AdaptiveStack(horizontalAlignment: .leading, verticalAlignment: .bottom, spacing: 8) {
            nextStopLabel
            Spacer(minLength: 0)
            continueButton
        }
    }

    @ViewBuilder
    private var nextStopLabel: some View {
        if let name = progress.nextPlaceName {
            HStack(spacing: 10) {
                Text("itinerary.activeCard.next \(name)")
                    .font(.caption2)
                    .lineLimit(1)
                if let nextStopDistance {
                    Circle()
                        .frame(width: 3, height: 3)
                        .accessibilityHidden(true)
                    Text(nextStopDistance)
                        .font(.caption2.bold())
                        .lineLimit(1)
                        .layoutPriority(1)
                }
            }
            .foregroundStyle(Color.brandPurple800)
        }
    }

    private var continueButton: some View {
        Button(action: onContinue) {
            Text("itinerary.activeCard.continue")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    StripedCapsuleBackground(color: .brandOrange600, stripeColor: .black.opacity(0.02))
                }
                .contentShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityHint(Text(activeItinerary.name))
    }

    private static let base = Color(red: 242 / 255, green: 243 / 255, blue: 1)
    private static let warmTint = Color(red: 1, green: 207 / 255, blue: 111 / 255)
}

#Preview {
    ActiveItineraryProgressCard(
        activeItinerary: ActiveItinerary(
            templateID: "1",
            slug: "centro-historico",
            name: "Bora passear no centro histórico?",
            description: "",
            category: "historic",
            routeType: .fixed,
            objectives: [],
            targetCategory: nil,
            targetCount: nil,
            startedAt: .now,
            places: (0..<4).map { index in
                ItinerarySlot(
                    id: "\(index)",
                    placeID: "p\(index)",
                    placeName: "Largo da Ordem",
                    isCompleted: index < 2,
                    completedAt: nil,
                    stampID: nil
                )
            }
        ),
        nextStopDistance: "600 m",
        onContinue: {}
    )
    .padding(.horizontal, 16)
    .background(Color.profileBackground)
}
