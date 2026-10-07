import Foundation
import Observation

@Observable
final class RatingPromptViewModel {
    private let service: RatingPromptServicing
    private let store: PendingRatingStoring
    private let userIDProvider: @Sendable () -> String?
    private let userCoordinateProvider: @Sendable () async throws -> UserCoordinate
    private let now: @Sendable () -> Date
    private let sleep: @Sendable (Duration) async throws -> Void
    private var refreshGeneration = 0

    private(set) var pendingRating: PendingRating?
    private(set) var isPresented = false
    private(set) var isSubmitting = false
    private(set) var selectedTag: ImpressionTag?
    var errorMessage: String?

    init(
        service: RatingPromptServicing = RatingPromptService(),
        store: PendingRatingStoring = UserDefaultsPendingRatingStore(),
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.userID },
        userCoordinateProvider: @escaping @Sendable () async throws -> UserCoordinate = {
            try await LocationMapService().currentUserLocation()
        },
        now: @escaping @Sendable () -> Date = { Date() },
        sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        self.service = service
        self.store = store
        self.userIDProvider = userIDProvider
        self.userCoordinateProvider = userCoordinateProvider
        self.now = now
        self.sleep = sleep
    }

    /// Re-runs `refresh()` every `pollInterval` while a rating is pending, so leaving the place with the
    /// app in the foreground eventually triggers the prompt. Returns once there is nothing left to wait
    /// for (nothing pending, or the prompt is showing) or when the calling task is cancelled; the view
    /// restarts it whenever the map becomes visible and active again.
    func monitorLeaving() async {
        while !Task.isCancelled {
            await refresh()
            guard !isPresented, store.load() != nil else { return }
            do {
                try await sleep(RatingPromptPolicy.pollInterval)
            } catch {
                return
            }
        }
    }

    /// Shows the prompt when the user checked in recently, has moved away from the place and
    /// hasn't rated it yet. Safe to call repeatedly (map appears, app becomes active).
    func refresh() async {
        guard !isPresented, !isSubmitting else { return }

        refreshGeneration += 1
        let generation = refreshGeneration

        guard let stored = store.load(),
              let userID = userIDProvider(),
              stored.userID == userID else { return }

        guard !stored.isExpired(now: now(), window: RatingPromptPolicy.validityWindow) else {
            store.clear()
            return
        }

        guard let coordinate = try? await userCoordinateProvider(),
              generation == refreshGeneration,
              stored.hasLeft(userCoordinate: coordinate, threshold: RatingPromptPolicy.leaveDistance)
        else { return }

        do {
            if try await service.hasRated(placeID: stored.placeID) {
                guard generation == refreshGeneration else { return }
                store.clear()
                return
            }
        } catch {
            // Can't tell whether the user rated (the service already logged why): don't risk asking twice.
            return
        }
        guard generation == refreshGeneration else { return }

        AppLog.ratingPrompt.info("Presenting rating prompt placeId=\(stored.placeID)")
        pendingRating = stored
        selectedTag = nil
        errorMessage = nil
        isPresented = true
    }

    func select(_ tag: ImpressionTag) {
        guard !isSubmitting else { return }
        selectedTag = tag
    }

    func submit() async {
        guard !isSubmitting, let pendingRating, let selectedTag else { return }
        guard userIDProvider() != nil else {
            errorMessage = String(localized: "ratingPrompt.error.notAuthenticated")
            return
        }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            _ = try await service.submitRating(placeID: pendingRating.placeID, impressionTag: selectedTag)
            finish()
        } catch is CancellationError {
            return
        } catch APIError.httpStatus(409, _) {
            finish()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func dismiss() {
        finish()
    }

    private func finish() {
        refreshGeneration += 1
        store.clear()
        pendingRating = nil
        selectedTag = nil
        errorMessage = nil
        isPresented = false
    }
}
