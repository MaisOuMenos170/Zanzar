import Foundation
@testable import ZanzarProject

@MainActor
final class FakeOpeningReminderScheduler: OpeningReminderScheduling {
    var allowsNotifications = true
    var scheduled: [String: Date] = [:]
    private(set) var cancelAllCount = 0

    func isScheduled(placeID: String) async -> Bool { scheduled[placeID] != nil }

    func schedule(placeID: String, placeName: String, at date: Date) async throws -> Bool {
        guard allowsNotifications else { return false }
        scheduled[placeID] = date
        return true
    }

    func cancel(placeID: String) async { scheduled[placeID] = nil }

    func cancelAll() async {
        cancelAllCount += 1
        scheduled = [:]
    }
}
