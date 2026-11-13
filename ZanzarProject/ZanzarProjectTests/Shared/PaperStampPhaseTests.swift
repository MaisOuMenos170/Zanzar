import Testing
@testable import ZanzarProject

@MainActor
struct PaperStampPhaseTests {
    @Test func reduceMotionSettlesWithoutContact() {
        var phases: [PaperStampPhase] = []
        var contactCount = 0
        var settledCount = 0

        PaperStampPhase.play(
            size: .small,
            reduceMotion: true,
            update: { phases.append($0) },
            onContact: { contactCount += 1 },
            onSettled: { settledCount += 1 }
        )

        #expect(phases == [.settled])
        #expect(contactCount == 0)
        #expect(settledCount == 1)
    }
}
