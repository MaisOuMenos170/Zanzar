import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("ProfileCheckInsViewModel")
struct ProfileCheckInsViewModelTests {
    private static func checkIn(_ index: Int) -> ProfileCheckIn {
        ProfileCheckIn(
            id: "p\(index)|d",
            placeID: "p\(index)",
            placeName: "Lugar \(index)",
            date: .now,
            photoURL: nil,
            sealCategory: .park,
            impressionTag: nil
        )
    }

    @Test("the first page is loaded with the page size and keeps the cursor of the next one")
    func loadsFirstPage() async {
        let service = PagesServiceStub(pages: [
            ProfileCheckInsPage(checkIns: [Self.checkIn(1), Self.checkIn(2)], nextCursor: "cursor-1")
        ])
        let viewModel = ProfileCheckInsViewModel(service: service, userIDProvider: { "user-1" })

        await viewModel.load()

        #expect(viewModel.checkIns.count == 2)
        #expect(viewModel.hasMore)
        #expect(service.requests.first?.limit == ProfileCheckInsViewModel.pageSize)
        #expect(service.requests.first?.before == nil)
    }

    @Test("loading more appends the next page with the cursor and stops on the last one")
    func loadsMoreUntilTheEnd() async {
        let service = PagesServiceStub(pages: [
            ProfileCheckInsPage(checkIns: [Self.checkIn(1)], nextCursor: "cursor-1"),
            ProfileCheckInsPage(checkIns: [Self.checkIn(2)], nextCursor: nil)
        ])
        let viewModel = ProfileCheckInsViewModel(service: service, userIDProvider: { "user-1" })

        await viewModel.load()
        await viewModel.loadMore()
        await viewModel.loadMore()

        #expect(viewModel.checkIns.map(\.placeID) == ["p1", "p2"])
        #expect(!viewModel.hasMore)
        #expect(service.requests.count == 2)
        #expect(service.requests.last?.before == "cursor-1")
    }

    @Test("a check-in that comes on two pages is listed once")
    func dropsRepeats() async {
        let service = PagesServiceStub(pages: [
            ProfileCheckInsPage(checkIns: [Self.checkIn(1)], nextCursor: "c"),
            ProfileCheckInsPage(checkIns: [Self.checkIn(1), Self.checkIn(2)], nextCursor: nil)
        ])
        let viewModel = ProfileCheckInsViewModel(service: service, userIDProvider: { "user-1" })

        await viewModel.load()
        await viewModel.loadMore()

        #expect(viewModel.checkIns.map(\.placeID) == ["p1", "p2"])
    }

    @Test("a failed page waits for a retry instead of asking again by itself")
    func failedPageWaitsForRetry() async {
        let service = PagesServiceStub(pages: [
            ProfileCheckInsPage(checkIns: [Self.checkIn(1)], nextCursor: "c"),
            ProfileCheckInsPage(checkIns: [Self.checkIn(2)], nextCursor: nil)
        ])
        let viewModel = ProfileCheckInsViewModel(service: service, userIDProvider: { "user-1" })
        await viewModel.load()

        service.failsNextRequest = true
        await viewModel.loadMore()
        #expect(viewModel.loadMoreFailed)
        await viewModel.loadMore()
        // Only the first page went through: the failed one is not recorded and nothing asked again.
        #expect(service.requests.count == 1)

        await viewModel.retryLoadMore()
        #expect(!viewModel.loadMoreFailed)
        #expect(viewModel.checkIns.map(\.placeID) == ["p1", "p2"])
    }

    @Test("a check-ins page decodes the cursor and drops an entry with a bad date")
    func decodesPage() throws {
        let json = """
        {
          "checkIns": [
            { "placeId": "ChIJ1", "placeName": "Rua XV", "datetime": "2026-11-10T12:00:00.000Z",
              "imageUrl": null, "stamp": { "stampId": "stamp_center", "imageUrl": "/assets/stamps/center.png" } },
            { "placeId": "ChIJ2", "placeName": null, "datetime": "not a date", "imageUrl": null, "stamp": null }
          ],
          "nextCursor": "2026-11-10T12:00:00.000Z"
        }
        """
        let response = try JSONDecoder().decode(CheckInsPageAPIResponse.self, from: Data(json.utf8))

        let page = response.makePage()

        #expect(page.checkIns.count == 1)
        #expect(page.checkIns.first?.sealCategory == .center)
        #expect(page.nextCursor == "2026-11-10T12:00:00.000Z")
    }
}

private final class PagesServiceStub: ProfileServicing, @unchecked Sendable {
    private var pages: [ProfileCheckInsPage]
    var failsNextRequest = false
    private(set) var requests: [(limit: Int, before: String?)] = []

    init(pages: [ProfileCheckInsPage]) {
        self.pages = pages
    }

    func fetchProfile(userID: String, limit: Int) async throws -> Profile {
        throw APIError.invalidRequest
    }

    func logout() async throws {}

    func fetchCheckIns(userID: String, limit: Int, before: String?) async throws -> ProfileCheckInsPage {
        if failsNextRequest {
            failsNextRequest = false
            throw APIError.invalidRequest
        }
        requests.append((limit, before))
        return pages.isEmpty ? ProfileCheckInsPage(checkIns: [], nextCursor: nil) : pages.removeFirst()
    }
}
