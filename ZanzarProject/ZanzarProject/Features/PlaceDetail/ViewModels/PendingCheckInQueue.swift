import Foundation
import Observation

/// The check-ins made without a network, waiting to be sent. Each one is replayed with its original id and time,
/// so the backend never counts it twice.
@MainActor
@Observable
final class PendingCheckInQueue {
    static let shared = PendingCheckInQueue()

    struct FlushResult: Equatable {
        /// Registered now, or already registered earlier (the backend answered 409).
        var sent: [PendingCheckIn] = []
        /// The backend refused them for good (the user was too far): they are gone from the queue.
        var refused: [PendingCheckIn] = []
        /// Still waiting, because the network is down or the backend failed.
        var remaining = 0
    }

    private let store: PendingCheckInStoring
    private let service: PlaceDetailServicing
    private let userIDProvider: @Sendable () -> String?
    private var items: [PendingCheckIn]
    private var isFlushing = false

    init(
        store: PendingCheckInStoring? = nil,
        service: PlaceDetailServicing = PlaceDetailService(),
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.userID }
    ) {
        let store = store ?? UserDefaultsPendingCheckInStore()
        self.store = store
        self.service = service
        self.userIDProvider = userIDProvider
        items = store.load()
    }

    /// The signed-in user's waiting check-ins, oldest first.
    var pending: [PendingCheckIn] {
        guard let userID = userIDProvider() else { return [] }
        return items.filter { $0.userID == userID }.sorted { $0.checkedInAt < $1.checkedInAt }
    }

    var count: Int { pending.count }

    func contains(placeID: String) -> Bool {
        pending.contains { $0.placeID == placeID }
    }

    /// Keeps a check-in for later. A second one for the same place replaces the first (one check-in per place).
    func enqueue(_ item: PendingCheckIn) {
        items.removeAll { $0.userID == item.userID && $0.placeID == item.placeID }
        items.append(item)
        store.save(items)
    }

    /// Drops the signed-in user's waiting check-ins (they chose to leave without sending them).
    func discardPending() {
        guard let userID = userIDProvider() else { return }
        items.removeAll { $0.userID == userID }
        store.save(items)
    }

    /// Sends what is waiting, oldest first, and stops at the first failure that a retry could fix.
    @discardableResult
    func flush() async -> FlushResult {
        var result = FlushResult()
        guard !isFlushing, userIDProvider() != nil else { return result }
        isFlushing = true
        defer { isFlushing = false }

        for item in pending {
            do {
                _ = try await service.checkIn(
                    placeID: item.placeID,
                    coordinate: item.coordinate,
                    mutationID: item.id,
                    datetime: item.checkedInAt
                )
                remove(item)
                result.sent.append(item)
            } catch APIError.httpStatus(409, _) {
                remove(item)
                result.sent.append(item)
            } catch APIError.httpStatus(422, _) {
                remove(item)
                result.refused.append(item)
            } catch is CancellationError {
                break
            } catch {
                AppLog.placeDetail.warning("Pending check-in kept for later placeId=\(item.placeID)")
                break
            }
        }
        result.remaining = count
        if !result.sent.isEmpty {
            NotificationCenter.default.post(name: AppNotification.checkInDidSucceed, object: nil)
        }
        return result
    }

    private func remove(_ item: PendingCheckIn) {
        items.removeAll { $0.id == item.id }
        store.save(items)
    }
}
