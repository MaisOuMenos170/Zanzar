import SwiftUI

/// The seals of a roteiro on a ticket: a card with a notch on each side, a row of seals (earned or still a "?"),
/// how many were collected and the tags of the roteiro (Figma "checkin v2", node 2313:6941).
struct ItineraryTicketCard: View {
    let slots: [ItinerarySealSlot]
    let collectedCount: Int
    let tags: [String]

    private static let slotSize: CGFloat = 44.787
    private static let earnedSealSize: CGFloat = 55

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(slots) { slot in
                        seal(for: slot)
                    }
                }
                .padding(.vertical, 5)
            }
            .scrollIndicators(.hidden)
            // The earned seals are bigger than their slot and spill a little over it.
            .scrollClipDisabled()

            Text("itinerary.detail.stampsCollected \(collectedCount) \(slots.count)")
                .font(.caption2)
                .foregroundStyle(.black)

            if !tags.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 4) {
                        ForEach(tags, id: \.self) { tag in
                            ItineraryTagChip(text: tag)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
            }
        }
        .padding(.horizontal, 16.5)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 149, alignment: .leading)
        .background {
            TicketShape()
                .fill(Self.base)
                .overlay {
                    TicketShape()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Self.tint.opacity(0.2), location: 0.0699),
                                    .init(color: .white.opacity(0.2), location: 0.99885)
                                ],
                                startPoint: UnitPoint(x: 0.952, y: -0.185),
                                endPoint: UnitPoint(x: 0.048, y: 1.185)
                            )
                        )
                }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("itinerary.stampTrack.progress \(collectedCount) \(slots.count)"))
    }

    private func seal(for slot: ItinerarySealSlot) -> some View {
        ZStack {
            if slot.isEarned {
                PlaceCategorySealView(category: slot.category, state: .earned, size: Self.earnedSealSize)
            } else {
                CheckInUnknownSealView(size: Self.slotSize)
            }
        }
        .frame(width: Self.slotSize, height: Self.slotSize)
    }

    private static let base = Color(red: 242 / 255, green: 243 / 255, blue: 1)
    private static let tint = Color(red: 161 / 255, green: 162 / 255, blue: 1)
}

/// A rounded card with a half circle cut out of the middle of each side.
struct TicketShape: Shape {
    var cornerRadius: CGFloat = 16
    var notchRadius: CGFloat = 10.5

    func path(in rect: CGRect) -> Path {
        let card = Path(roundedRect: rect, cornerRadius: cornerRadius)
        let diameter = notchRadius * 2
        let leading = Path(ellipseIn: CGRect(
            x: rect.minX - notchRadius, y: rect.midY - notchRadius, width: diameter, height: diameter
        ))
        let trailing = Path(ellipseIn: CGRect(
            x: rect.maxX - notchRadius, y: rect.midY - notchRadius, width: diameter, height: diameter
        ))
        return card.subtracting(leading).subtracting(trailing)
    }
}

/// A small outlined tag ("Histórico", "Museu").
struct ItineraryTagChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(Color.brandNeutral600)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background { Capsule().strokeBorder(Color.brandChipBorder, lineWidth: 1) }
    }
}

#Preview {
    ItineraryTicketCard(
        slots: [
            ItinerarySealSlot(id: 0, category: .park, isEarned: true),
            ItinerarySealSlot(id: 1, category: .park, isEarned: true),
            ItinerarySealSlot(id: 2, category: .park, isEarned: false),
            ItinerarySealSlot(id: 3, category: .park, isEarned: false)
        ],
        collectedCount: 2,
        tags: ["Histórico", "Museu", "Café"]
    )
    .padding()
    .background(Color.white)
}
