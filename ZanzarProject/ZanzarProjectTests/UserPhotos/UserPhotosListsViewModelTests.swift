import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("My photos, reporting and status notices")
struct UserPhotosListsViewModelTests {
    @Test("deleting asks first and then removes the photo from the list")
    func deletePhoto() async {
        let service = MockUserPhotosService()
        service.myPhotos = .success([.fixture(id: "a"), .fixture(id: "b", status: .approved)])
        let viewModel = MyPhotosViewModel(service: service, userIDProvider: { "user-1" })
        await viewModel.load()

        viewModel.photoPendingDeletion = viewModel.photos.first
        await viewModel.confirmDeletion()

        #expect(service.deletedPhotoIDs == ["a"])
        #expect(viewModel.photos.map(\.id) == ["b"])
    }

    @Test("a failed delete keeps the photo and explains it")
    func failedDelete() async {
        let service = MockUserPhotosService()
        service.myPhotos = .success([.fixture(id: "a")])
        service.deleteError = APIError.httpStatus(500, message: nil)
        let viewModel = MyPhotosViewModel(service: service, userIDProvider: { "user-1" })
        await viewModel.load()
        viewModel.photoPendingDeletion = viewModel.photos.first
        await viewModel.confirmDeletion()
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
}

private final class MemoryStatusStore: UserPhotoStatusStoring {
    private var statuses: [String: String] = [:]
    func lastSeenStatuses() -> [String: String] { statuses }
    func save(_ statuses: [String: String]) { self.statuses = statuses }
}
