import SwiftUI

struct ItineraryStampTrack: View {
    let slots: [Slot]

    @ScaledMetric(relativeTo: .caption) private var stampSize = 44
    @ScaledMetric(relativeTo: .caption) private var waveOffset = 14
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Stamps already on the paper. The first set the track sees is quiet, so a full row does not press in.
    @State private var quietIDs: Set<String>
    @State private var pressQueue: [String] = []
    @State private var pressingID: String?
    @State private var pressPhase = PaperStampPhase.lifted
    @State private var landingCount = 0
    @State private var pressGeneration = 0
    @State private var isVisible = false

    struct Slot: Identifiable {
        let id: String
        let isEarned: Bool
    }

    init(slots: [Slot]) {
        self.slots = slots
        _quietIDs = State(initialValue: Set(slots.filter(\.isEarned).map(\.id)))
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
        .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.7), trigger: landingCount)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("itinerary.stampTrack.progress \(earnedCount) \(slots.count)"))
        .onAppear {
            isVisible = true
            revealQueuedStamps()
        }
        .onDisappear {
            isVisible = false
            pressGeneration += 1
            if let pressingID {
                pressQueue.insert(pressingID, at: 0)
                self.pressingID = nil
            }
        }
        .onChange(of: earnedToken) { _, _ in
            enqueueNewlyEarnedSlots()
        }
        .onChange(of: pressingID) { _, newID in
            guard let newID else { return }
            let generation = pressGeneration
            PaperStampPhase.play(
                duration: 0.45,
                reduceMotion: reduceMotion,
                update: { pressPhase = $0 },
                onContact: { landingCount += 1 },
                onSettled: {
                    guard generation == pressGeneration, pressingID == newID else { return }
                    quietIDs.insert(newID)
                    pressingID = nil
                    revealQueuedStamps()
                }
            )
        }
    }

    private var earnedCount: Int {
        slots.filter(\.isEarned).count
    }

    private var earnedToken: String {
        slots.map { "\($0.id):\($0.isEarned)" }.joined(separator: "|")
    }

    @ViewBuilder
    private func stamp(for slot: Slot) -> some View {
        let isShownEarned = quietIDs.contains(slot.id) || pressingID == slot.id
        let phase = pressingID == slot.id ? pressPhase : PaperStampPhase.settled

        Group {
            if isShownEarned {
                ItineraryStampView(state: .earned, size: stampSize)
                    .paperStampPress(phase: phase, role: .mark, travel: 12)
            } else {
                ItineraryPendingStampView(size: stampSize)
            }
        }
        .paperStampPress(phase: phase, role: .sheet, travel: 12)
    }

    private func enqueueNewlyEarnedSlots() {
        let currentIDs = Set(slots.map(\.id))
        let knownIDs = quietIDs
            .union(pressQueue)
            .union(pressingID.map { [$0] } ?? [])
        if knownIDs.isDisjoint(with: currentIDs), !currentIDs.isEmpty, !quietIDs.isEmpty {
            quietIDs = Set(slots.filter(\.isEarned).map(\.id))
            pressQueue.removeAll()
            pressingID = nil
            pressGeneration += 1
            return
        }

        for slot in slots where slot.isEarned && !knownIDs.contains(slot.id) {
            pressQueue.append(slot.id)
        }
        revealQueuedStamps()
    }

    /// Shows the next queued stamp. The press itself starts from `onChange(of: pressingID)`,
    /// after this frame has drawn the mark lifted off the paper.
    private func revealQueuedStamps() {
        if reduceMotion {
            quietIDs.formUnion(pressQueue)
            if let pressingID {
                quietIDs.insert(pressingID)
            }
            pressQueue.removeAll()
            pressingID = nil
            return
        }

        guard isVisible, pressingID == nil, !pressQueue.isEmpty else { return }

        let id = pressQueue.removeFirst()
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            pressPhase = .lifted
            pressingID = id
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
        .init(id: "4", isEarned: false)
    ])
    .padding()
    .background(Color("ItineraryProgressBackground"))
}
