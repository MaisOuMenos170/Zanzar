import Foundation
@testable import ZanzarProject

@MainActor
final class InMemoryPendingCheckInStore: PendingCheckInStoring {
    var items: [PendingCheckIn]

    init(items: [PendingCheckIn] = []) {
        self.items = items
    }

    func load() -> [PendingCheckIn] { items }
    func save(_ items: [PendingCheckIn]) { self.items = items }
}
