import CoreGraphics
import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("PhotoUploadViewModel")
struct PhotoUploadViewModelTests {
    private func makeViewModel(
        service: MockUserPhotosService = MockUserPhotosService(),
        processing: FakePhotoProcessing = FakePhotoProcessing(),
        sensitive: Bool? = nil,
        checker: FixedSensitiveContent? = nil,
        online: Bool = true,
        fromCheckIn: Bool = false
    ) -> PhotoUploadViewModel {
        PhotoUploadViewModel(
            placeID: "place-1", placeName: "Bar do Teste", fromCheckIn: fromCheckIn,
            service: service, processing: processing, sensitiveContent: checker ?? FixedSensitiveContent(answer: sensitive),
            userIDProvider: { "user-1" }, isOnline: { online }
        )
    }

    private static let fullEdit = PhotoEdit(quarterTurns: 0, cropRect: CGRect(x: 0, y: 0, width: 8, height: 6))

    /// Picks a file and confirms the editor without changing anything, which runs the on-device checks.
    private func pickAndEdit(_ viewModel: PhotoUploadViewModel) async {
        await viewModel.pick(Data([1]))
        #expect(viewModel.step == .editing)
        await viewModel.applyEdit(Self.fullEdit)
    }

    @Test("shows the terms first when the current terms were not accepted")
    func needsTerms() async {
        let service = MockUserPhotosService()
        service.termsStatus = .success(PhotoTermsStatus(hasAcceptedCurrentTerms: false, isAdult: nil))
        let viewModel = makeViewModel(service: service)

        await viewModel.start()

        #expect(viewModel.step == .needsTerms)
        viewModel.termsAccepted()
        #expect(viewModel.step == .choosing)
    }

    @Test("a declared minor never reaches the photo picker")
    func minorCannotUpload() async {
        let service = MockUserPhotosService()
        service.termsStatus = .success(PhotoTermsStatus(hasAcceptedCurrentTerms: true, isAdult: false))
        let viewModel = makeViewModel(service: service)
        await viewModel.start()
        #expect(viewModel.step == .needsTerms)
    }

    @Test("a photo without faces goes straight to the preview and is sent with the chosen options")
    func sendsPhoto() async throws {
        let service = MockUserPhotosService()
        let viewModel = makeViewModel(service: service, fromCheckIn: true)
        await viewModel.start()

        await pickAndEdit(viewModel)
        #expect(viewModel.step == .preview)
        viewModel.showsAuthorName = false
        await viewModel.send()

        #expect(viewModel.step == .sent(.pending))
        let upload = try #require(service.uploads.first)
        #expect(upload.placeID == "place-1")
        #expect(upload.fromCheckIn)
        #expect(upload.showsAuthorName == false)
    }

    @Test("a large face asks the user, and blurring shows the pixelated photo before sending")
    func faceWarningThenBlur() async {
        let processing = FakePhotoProcessing()
        processing.faces = [CGRect(x: 0.3, y: 0.3, width: 0.3, height: 0.3)]
        let viewModel = makeViewModel(processing: processing)

        await pickAndEdit(viewModel)
        #expect(viewModel.step == .faceWarning)
        #expect(viewModel.faceCount == 1)

        await viewModel.blurFaces()
        #expect(viewModel.step == .preview)
        #expect(viewModel.hasBlurredFaces)
        #expect(processing.blurredFaces == processing.faces)
    }

    @Test("choosing another photo after the face warning drops the first one")
    func chooseAnotherAfterFaceWarning() async {
        let processing = FakePhotoProcessing()
        processing.faces = [CGRect(x: 0.2, y: 0.2, width: 0.5, height: 0.5)]
        let viewModel = makeViewModel(processing: processing)
        await pickAndEdit(viewModel)

        viewModel.chooseAnother()

        #expect(viewModel.step == .choosing)
        #expect(viewModel.image == nil)
    }

    @Test("small faces in the background do not trigger the warning")
    func smallFacesAreFine() async {
        let processing = FakePhotoProcessing()
        processing.faces = [CGRect(x: 0.1, y: 0.1, width: 0.05, height: 0.05)]
        let viewModel = makeViewModel(processing: processing)
        await pickAndEdit(viewModel)
        #expect(viewModel.step == .preview)
    }

    @Test("Apple's sensitive content analysis blocks the photo on the device")
    func sensitiveContentIsRefused() async {
        let service = MockUserPhotosService()
        let viewModel = makeViewModel(service: service, sensitive: true)
        await pickAndEdit(viewModel)
        #expect(viewModel.step == .failed(.sensitiveContent))
        #expect(viewModel.image == nil)
        #expect(service.uploads.isEmpty)
    }

    @Test("when the analysis is off (nil) the photo continues; the server still checks it")
    func analysisOffContinues() async {
        let viewModel = makeViewModel(sensitive: nil)
        await pickAndEdit(viewModel)
        #expect(viewModel.step == .preview)
    }

    @Test("a file too large to decode is explained", arguments: [
        (PhotoPreparer.Failure.tooLarge, PhotoUploadError.tooLarge),
        (PhotoPreparer.Failure.unreadable, PhotoUploadError.unreadable)
    ])
    func unreadableFiles(failure: PhotoPreparer.Failure, expected: PhotoUploadError) async {
        let processing = FakePhotoProcessing()
        processing.downsampleError = failure
        let viewModel = makeViewModel(processing: processing)
        await viewModel.pick(Data([1]))
        #expect(viewModel.step == .failed(expected))
    }

    @Test("offline: nothing is sent and retry brings the same photo back")
    func offlineThenRetry() async {
        let service = MockUserPhotosService()
        let viewModel = makeViewModel(service: service, online: false)
        await pickAndEdit(viewModel)

        await viewModel.send()
        #expect(viewModel.step == .failed(.offline))
        #expect(service.uploads.isEmpty)

        viewModel.recover()
        #expect(viewModel.step == .preview)
        #expect(viewModel.image != nil)
    }

    @Test("a duplicate is not retryable: recovering goes back to choosing")
    func duplicateGoesBackToChoosing() async {
        let service = MockUserPhotosService()
        service.uploadResult = .failure(PhotoUploadError.duplicate)
        let viewModel = makeViewModel(service: service)
        await pickAndEdit(viewModel)

        await viewModel.send()
        #expect(viewModel.step == .failed(.duplicate))
        viewModel.recover()
        #expect(viewModel.step == .choosing)
    }

    @Test("terms refused by the server send the user back to the terms")
    func termsRequiredFromServer() async {
        let service = MockUserPhotosService()
        service.uploadResult = .failure(PhotoUploadError.termsRequired)
        let viewModel = makeViewModel(service: service)
        await pickAndEdit(viewModel)
        await viewModel.send()
        viewModel.recover()
        #expect(viewModel.step == .needsTerms)
    }

    @Test("picking a photo stops at the editor: the on-device checks wait for the edited photo")
    func pickStopsAtEditing() async {
        let viewModel = makeViewModel(sensitive: true)
        await viewModel.pick(Data([1]))
        #expect(viewModel.step == .editing)
        #expect(viewModel.original != nil)
        #expect(viewModel.image == nil)
    }

    @Test("the edit is applied first, then the checks run on the result")
    func appliesTheEditBeforeTheChecks() async {
        let processing = FakePhotoProcessing()
        let viewModel = makeViewModel(processing: processing)
        await viewModel.pick(Data([1]))
        let edit = PhotoEdit(quarterTurns: 1, cropRect: CGRect(x: 0, y: 0, width: 6, height: 4))
        await viewModel.applyEdit(edit)
        #expect(processing.appliedEdits == [edit])
        #expect(viewModel.step == .preview)

        processing.faces = [CGRect(x: 0.3, y: 0.3, width: 0.3, height: 0.3)]
        viewModel.editAgain()
        await viewModel.applyEdit(edit)
        #expect(viewModel.step == .faceWarning)
    }

    @Test("the checks and the upload see the edited photo, never the original")
    func checksAndUploadUseTheEditedPhoto() async {
        let processing = FakePhotoProcessing()
        let checker = FixedSensitiveContent(answer: false)
        let viewModel = makeViewModel(processing: processing, checker: checker)
        await viewModel.pick(Data([1]))
        await viewModel.applyEdit(Self.fullEdit)
        await viewModel.send()

        #expect(viewModel.original === FakePhotoProcessing.image)
        #expect(checker.checkedImages.count == 1)
        #expect(checker.checkedImages.first === FakePhotoProcessing.edited)
        #expect(processing.facesRequestedFor.count == 1)
        #expect(processing.facesRequestedFor.first === FakePhotoProcessing.edited)
        #expect(processing.encodedImages.count == 1)
        #expect(processing.encodedImages.first === FakePhotoProcessing.edited)
    }

    @Test("sensitive content is judged on the edited photo")
    func sensitiveContentIsCheckedOnTheEditedPhoto() async {
        let viewModel = makeViewModel(sensitive: true)
        await viewModel.pick(Data([1]))
        await viewModel.applyEdit(Self.fullEdit)
        #expect(viewModel.step == .failed(.sensitiveContent))
        #expect(viewModel.image == nil)
    }

    @Test("an edit that cannot be applied is reported as an unreadable photo")
    func failedEditIsUnreadable() async {
        let processing = FakePhotoProcessing()
        processing.editResult = nil
        let viewModel = makeViewModel(processing: processing)
        await viewModel.pick(Data([1]))
        await viewModel.applyEdit(Self.fullEdit)
        #expect(viewModel.step == .failed(.unreadable))
    }

    @Test("cancelling the editor goes back to choosing and forgets the photo")
    func cancelEditingGoesBackToChoosing() async {
        let viewModel = makeViewModel()
        await viewModel.pick(Data([1]))
        viewModel.cancelEditing()
        #expect(viewModel.step == .choosing)
        #expect(viewModel.original == nil)
    }

    @Test("editing again starts from the original photo, not the pixelated one, and checks again")
    func editAgainStartsFromTheOriginal() async {
        let processing = FakePhotoProcessing()
        processing.faces = [CGRect(x: 0.3, y: 0.3, width: 0.3, height: 0.3)]
        let viewModel = makeViewModel(processing: processing)
        await pickAndEdit(viewModel)
        await viewModel.blurFaces()
        #expect(viewModel.hasBlurredFaces)

        viewModel.editAgain()
        #expect(viewModel.step == .editing)
        #expect(viewModel.original != nil)
        #expect(viewModel.image == nil)
        #expect(viewModel.hasBlurredFaces == false)
        #expect(viewModel.faceCount == 0)

        await viewModel.applyEdit(Self.fullEdit)
        #expect(processing.appliedEdits.count == 2)
        #expect(viewModel.step == .faceWarning)
    }

    @Test("editing again is ignored when there is no photo to edit")
    func editAgainIsIgnoredOutsidePreview() {
        let viewModel = makeViewModel()
        viewModel.editAgain()
        #expect(viewModel.step == .checkingTerms)
    }
}
