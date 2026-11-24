import Testing
@testable import ZanzarProject

@MainActor
@Suite("ItineraryTicketCard")
struct ItineraryTicketCardTests {
    @Test("emphasis grows from nothing done to everything done")
    func emphasisGrows() {
        #expect(ItineraryTicketCard.emphasis(collected: 0, total: 4) == 0)
        #expect(ItineraryTicketCard.emphasis(collected: 1, total: 4) == 0.25)
        #expect(ItineraryTicketCard.emphasis(collected: 4, total: 4) == 1)
    }

    @Test("emphasis stays between 0 and 1, whatever the numbers")
    func emphasisIsClamped() {
        #expect(ItineraryTicketCard.emphasis(collected: 9, total: 4) == 1)
        #expect(ItineraryTicketCard.emphasis(collected: -1, total: 4) == 0)
        #expect(ItineraryTicketCard.emphasis(collected: 2, total: 0) == 0)
    }
}
