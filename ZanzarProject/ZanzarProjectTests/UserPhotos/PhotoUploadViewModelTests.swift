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
        online: Bool = true,
        fromCheckIn: Bool = false
    ) -> PhotoUploadViewModel {
        PhotoUploadViewModel(
            placeID: "place-1", placeName: "Bar do Teste", fromCheckIn: fromCheckIn,
            service: service, processing: processing, sensitiveContent: FixedSensitiveContent(answer: sensitive),
            userIDProvider: { "user-1" }, isOnline: { online }
        )
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

        await viewModel.pick(Data([1, 2, 3]))
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

        await viewModel.pick(Data([1]))
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
        await viewModel.pick(Data([1]))

        viewModel.chooseAnother()

        #expect(viewModel.step == .choosing)
        #expect(viewModel.image == nil)
    }

    @Test("small faces in the background do not trigger the warning")
    func smallFacesAreFine() async {
        let processing = FakePhotoProcessing()
        processing.faces = [CGRect(x: 0.1, y: 0.1, width: 0.05, height: 0.05)]
        let viewModel = makeViewModel(processing: processing)
        await viewModel.pick(Data([1]))
        #expect(viewModel.step == .preview)
    }

    @Test("Apple's sensitive content analysis blocks the photo on the device")
    func sensitiveContentIsRefused() async {
        let service = MockUserPhotosService()
        let viewModel = makeViewModel(service: service, sensitive: true)
        await viewModel.pick(Data([1]))
        #expect(viewModel.step == .failed(.sensitiveContent))
        #expect(viewModel.image == nil)
        #expect(service.uploads.isEmpty)
    }

    @Test("when the analysis is off (nil) the photo continues; the server still checks it")
    func analysisOffContinues() async {
        let viewModel = makeViewModel(sensitive: nil)
        await viewModel.pick(Data([1]))
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
        await viewModel.pick(Data([1]))

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
        await viewModel.pick(Data([1]))

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
        await viewModel.pick(Data([1]))
        await viewModel.send()
        viewModel.recover()
        #expect(viewModel.step == .needsTerms)
    }
}
