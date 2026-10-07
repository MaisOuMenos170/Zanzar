import Foundation
import Observation

@Observable
final class ItineraryDetailViewModel {
    let slug: String

    private let service: ItineraryServicing
    private let userIDProvider: @Sendable () -> String?
    private var loadGeneration = 0

    var detail: ItineraryDetail?
    var activeItinerary: ActiveItinerary?
    var isLoading = false
    var isPerformingAction = false
    var errorMessage: String?
    var actionErrorMessage: String?

    init(
        slug: String,
        service: ItineraryServicing = ItineraryService(),
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.getToken().flatMap(JWTDecoder.userID(from:)) }
    ) {
        self.slug = slug
        self.service = service
        self.userIDProvider = userIDProvider
    }

    var isCurrentItineraryActive: Bool {
        activeItinerary?.slug == slug
    }

    var hasDifferentActiveItinerary: Bool {
        guard let activeItinerary else { return false }
        return activeItinerary.slug != slug
    }

    func load() async {
        loadGeneration += 1
        let generation = loadGeneration

        isLoading = true
        errorMessage = nil
        defer {
            if generation == loadGeneration {
                isLoading = false
            }
        }

        do {
            async let detailTask = service.fetchItineraryDetail(slug: slug)
            async let activeTask = fetchActiveItineraryIfAuthenticated()

            let loadedDetail = try await detailTask
            guard generation == loadGeneration else { return }

            detail = loadedDetail
            activeItinerary = try await activeTask
        } catch is CancellationError {
            return
        } catch {
            guard generation == loadGeneration else { return }
            errorMessage = String(localized: "itinerary.detail.errorState.message")
        }
    }

    @discardableResult
    func activateItinerary() async -> Bool {
        guard !isPerformingAction else { return false }
        isPerformingAction = true
        actionErrorMessage = nil
        defer { isPerformingAction = false }

        do {
            let active = try await service.activateItinerary(slug: slug)
            activeItinerary = active
            return true
        } catch is CancellationError {
            return false
        } catch let error as APIError {
            actionErrorMessage = Self.message(forActivationError: error)
            return false
        } catch {
            actionErrorMessage = String(localized: "itinerary.detail.actionError.generic")
            return false
        }
    }

    @discardableResult
    func abandonItinerary() async -> Bool {
        guard !isPerformingAction else { return false }
        isPerformingAction = true
        actionErrorMessage = nil
        defer { isPerformingAction = false }

        do {
            try await service.abandonActiveItinerary()
            activeItinerary = nil
            return true
        } catch is CancellationError {
            return false
        } catch {
            actionErrorMessage = String(localized: "itinerary.detail.actionError.generic")
            return false
        }
    }

    private func fetchActiveItineraryIfAuthenticated() async throws -> ActiveItinerary? {
        guard let userID = userIDProvider() else { return nil }
        return try await service.fetchActiveItinerary(userID: userID)
    }

    private static func message(forActivationError error: APIError) -> String {
        if case .httpStatus(409, _) = error {
            String(localized: "itinerary.detail.actionError.alreadyActive")
        } else {
            String(localized: "itinerary.detail.actionError.generic")
        }
    }
}
