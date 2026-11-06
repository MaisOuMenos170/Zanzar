import Foundation
@testable import ZanzarProject

/// A `ProximityNotifying` that keeps what would have been shown.
final class FakeProximityNotifier: ProximityNotifying {
    struct PostFailure: Error {}

    var isAllowed = true
    var failsToPost = false
    private(set) var posted: [ProximityAlertContent] = []

    func canPost() async -> Bool {
        isAllowed
    }

    func post(_ content: ProximityAlertContent) async throws {
        if failsToPost { throw PostFailure() }
        posted.append(content)
    }
}
