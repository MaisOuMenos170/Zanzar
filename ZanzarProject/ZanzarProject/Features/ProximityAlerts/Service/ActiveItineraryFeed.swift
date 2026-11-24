import Foundation

/// Keeps the proximity alerts told about the roteiro the user is following. Anything that can change it (starting,
/// abandoning, a check-in that advances it, coming back to the app) just calls `refresh()`; the server answer
/// decides, so an abandoned roteiro stops being alerted without every screen having to say so.
final class ActiveItineraryFeed {
    private let service: ItineraryServicing
    private let userIDProvider: @Sendable () -> String?
    private let apply: (ActiveItinerary?) async -> Void
    private var task: Task<Void, Never>?

    init(
        service: ItineraryServicing,
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.userID },
        apply: @escaping (ActiveItinerary?) async -> Void
    ) {
        self.service = service
        self.userIDProvider = userIDProvider
        self.apply = apply
    }

    /// Asks the server again. A refresh still running is dropped: bursts of signals end in one answer, and an
    /// answer that arrives after a newer request was made is never applied.
    @discardableResult
    func refresh() -> Task<Void, Never> {
        task?.cancel()
        let newTask = Task { [weak self] in
            guard let self else { return }
            await load()
        }
        task = newTask
        return newTask
    }

    func load() async {
        guard let userID = userIDProvider() else {
            await apply(nil)
            return
        }
        do {
            let active = try await service.fetchActiveItinerary(userID: userID)
            guard !Task.isCancelled else { return }
            await apply(active)
        } catch is CancellationError {
            return
        } catch {
            // Keep what is known: being offline must not make the roteiro disappear.
            AppLog.proximity.warning("Failed to refresh the active roteiro for the proximity alerts")
        }
    }
}
