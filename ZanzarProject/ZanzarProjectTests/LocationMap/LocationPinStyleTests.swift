import Testing
@testable import ZanzarProject

struct LocationPinStyleTests {
    @Test func availablePinBecomingCheckedInEarnsTheStamp() {
        #expect(LocationPinStyle.earnedStamp(from: .available, to: .checkedIn))
    }

    @Test func itineraryPinBecomingCheckedInEarnsTheStamp() {
        #expect(LocationPinStyle.earnedStamp(from: .inCurrentItinerary, to: .checkedIn))
    }

    @Test func checkedInPinStayingCheckedInDoesNotEarnAgain() {
        #expect(!LocationPinStyle.earnedStamp(from: .checkedIn, to: .checkedIn))
    }

    @Test func pinLeavingCheckedInDoesNotEarnTheStamp() {
        #expect(!LocationPinStyle.earnedStamp(from: .checkedIn, to: .inCurrentItinerary))
    }
}
