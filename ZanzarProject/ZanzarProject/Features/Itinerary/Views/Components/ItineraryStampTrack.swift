import SwiftUI

struct ItineraryStampTrack: View {
    let slots: [Slot]

    @ScaledMetric(relativeTo: .caption) private var stampSize = 44
    @ScaledMetric(relativeTo: .caption) private var waveOffset = 14

    struct Slot: Identifiable {
        let id: String
        let isEarned: Bool
    }

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            ForEach(slots.enumerated(), id: \.element.id) { index, slot in
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: index.isMultiple(of: 2) ? waveOffset * 2 : 0)
                    stamp(for: slot)
                    Color.clear
                        .frame(height: index.isMultiple(of: 2) ? 0 : waveOffset * 2)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("itinerary.stampTrack.progress \(earnedCount) \(slots.count)"))
    }

    private var earnedCount: Int {
        slots.filter(\.isEarned).count
    }

    @ViewBuilder
    private func stamp(for slot: Slot) -> some View {
        if slot.isEarned {
            ItineraryStampView(state: .earned, size: stampSize)
        } else {
            ItineraryPendingStampView(size: stampSize)
        }
    }
}

private struct ItineraryPendingStampView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(.systemBackground).opacity(0.55))
            Image(systemName: "questionmark")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .frame(width: size, height: size)
        .overlay {
            Circle()
                .strokeBorder(Color(.systemGray), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        }
    }
}

#Preview("Progress") {
    ItineraryStampTrack(slots: [
        .init(id: "1", isEarned: true),
        .init(id: "2", isEarned: false),
        .init(id: "3", isEarned: false),
        .init(id: "4", isEarned: false),
    ])
    .padding()
    .background(Color("ItineraryProgressBackground"))
}
