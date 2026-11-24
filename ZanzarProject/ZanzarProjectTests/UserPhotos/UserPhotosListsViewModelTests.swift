import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("My photos, reporting and status notices")
struct UserPhotosListsViewModelTests {
    @Test("deleting asks first and then removes the photo from the list")
    func deletePhoto() async throws {
        let service = MockUserPhotosService()
        service.myPhotos = .success([.fixture(id: "a"), .fixture(id: "b", status: .approved)])
        let viewModel = MyPhotosViewModel(service: service, userIDProvider: { "user-1" })
        await viewModel.load()

        viewModel.photoPendingDeletion = viewModel.photos.first
        // The alert clears the pending photo before its button runs, as SwiftUI does.
        let confirmed = try #require(viewModel.photoPendingDeletion)
        viewModel.photoPendingDeletion = nil
        await viewModel.delete(confirmed)

        #expect(service.deletedPhotoIDs == ["a"])
        #expect(viewModel.photos.map(\.id) == ["b"])
    }

    @Test("a failed delete keeps the photo and explains it")
    func failedDelete() async throws {
        let service = MockUserPhotosService()
        service.myPhotos = .success([.fixture(id: "a")])
        service.deleteError = APIError.httpStatus(500, message: nil)
        let viewModel = MyPhotosViewModel(service: service, userIDProvider: { "user-1" })
        await viewModel.load()
        viewModel.photoPendingDeletion = viewModel.photos.first
        // The alert clears the pending photo before its button runs, as SwiftUI does.
        let confirmed = try #require(viewModel.photoPendingDeletion)
        viewModel.photoPendingDeletion = nil
        await viewModel.delete(confirmed)
        #expect(viewModel.photos.count == 1)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("report with a trimmed note, and block too when asked")
    func reportAndBlock() async throws {
        let service = MockUserPhotosService()
        let viewModel = ReportPhotoViewModel(
            photoID: "p1", placeID: "place-1", service: service, userIDProvider: { "user-1" }
        )
        #expect(!viewModel.canSubmit)
        viewModel.reason = .peopleOrPrivacy
        viewModel.note = "  sou eu na foto  "
        viewModel.alsoBlocksAuthor = true

        await viewModel.submit()

        let report = try #require(service.reports.first)
        #expect(report.reason == .peopleOrPrivacy)
        #expect(report.note == "sou eu na foto")
        #expect(service.blockedPhotoIDs == ["p1"])
        #expect(viewModel.didFinish)
    }

    @Test("the status notice stays quiet on the first run and speaks once per change")
    func statusNotice() async {
        let service = MockUserPhotosService()
        let store = MemoryStatusStore()
        let viewModel = PhotoStatusNoticeViewModel(service: service, store: store, userIDProvider: { "user-1" })

        service.myPhotos = .success([.fixture(id: "a", status: .pending), .fixture(id: "b", status: .needsReview)])
        #expect(await viewModel.checkForChanges() == nil)

        service.myPhotos = .success([.fixture(id: "a", status: .approved), .fixture(id: "b", status: .needsReview)])
        let message = await viewModel.checkForChanges()
        #expect(message == L10n.string("userPhotos.notice.published", 1))

        #expect(await viewModel.checkForChanges() == nil)
    }

    @Test("a photo sent and reviewed since the last check is told even though it was never seen pending")
    func noticeForPhotoSentInSession() async {
        let service = MockUserPhotosService()
        let store = MemoryStatusStore()
        var clock = Date(timeIntervalSince1970: 1_800_000_000)
        let viewModel = PhotoStatusNoticeViewModel(
            service: service, store: store, userIDProvider: { "user-1" }, now: { clock }
        )

        service.myPhotos = .success([])
        #expect(await viewModel.checkForChanges() == nil)

        clock = clock.addingTimeInterval(3600)
        let rejected = UserPhoto(
            id: "new", placeID: "p", placeName: nil, status: .rejected, isVerifiedCheckIn: false, showsAuthorName: true,
            thumbnailURL: nil, imageURL: nil, decisionReason: .personalData, createdAt: clock.addingTimeInterval(-600),
            decidedAt: clock.addingTimeInterval(-60)
        )
        service.myPhotos = .success([rejected])
        #expect(await viewModel.checkForChanges() == L10n.string("userPhotos.notice.notApproved", 1))
    }
}

private final class MemoryStatusStore: UserPhotoStatusStoring {
    private var statuses: [String: String] = [:]
    private var checkedAt: Date?
    func lastSeenStatuses() -> [String: String] { statuses }
    func lastCheckedAt() -> Date? { checkedAt }
    func save(_ statuses: [String: String], checkedAt: Date) {
        self.statuses = statuses
        self.checkedAt = checkedAt
    }
}
