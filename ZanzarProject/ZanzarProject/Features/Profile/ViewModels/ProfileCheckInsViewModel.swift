import Foundation
import Observation

@Observable
final class ProfileCheckInsViewModel {
    /// How many check-ins one request asks for (the backend takes up to 50).
    static let pageSize = 30

    private(set) var checkIns: [ProfileCheckIn] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var hasLoaded = false
    private(set) var errorMessage: String?
    /// The next page failed; the list shows a retry instead of loading again by itself.
    private(set) var loadMoreFailed = false
    private var nextCursor: String?

    private let service: ProfileServicing
    private let userIDProvider: @Sendable () -> String?

    init(
        service: ProfileServicing = ProfileService(),
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.userID }
    ) {
        self.service = service
        self.userIDProvider = userIDProvider
    }

    var hasMore: Bool {
        nextCursor != nil
    }

    /// Loads the first page again. A failed refresh keeps the check-ins already on screen.
    func load() async {
        guard let userID = userIDProvider() else {
            errorMessage = L10n.string("profile.loadError.notAuthenticated")
            hasLoaded = true
            return
        }
        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }
        do {
            let page = try await service.fetchCheckIns(userID: userID, limit: Self.pageSize, before: nil)
            checkIns = page.checkIns
            nextCursor = page.nextCursor
            errorMessage = nil
            loadMoreFailed = false
        } catch is CancellationError {
            return
        } catch {
            guard checkIns.isEmpty else { return }
            errorMessage = APIError.rateLimitedMessage(for: error) ?? L10n.string("profile.errorState.message")
        }
    }

    func loadMore() async {
        guard let cursor = nextCursor, !isLoading, !isLoadingMore, !loadMoreFailed,
              let userID = userIDProvider() else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await service.fetchCheckIns(userID: userID, limit: Self.pageSize, before: cursor)
            let known = Set(checkIns.map(\.id))
            checkIns += page.checkIns.filter { !known.contains($0.id) }
            nextCursor = page.nextCursor
        } catch is CancellationError {
            return
        } catch {
            loadMoreFailed = true
        }
    }

    func retryLoadMore() async {
        loadMoreFailed = false
        await loadMore()
    }
}
