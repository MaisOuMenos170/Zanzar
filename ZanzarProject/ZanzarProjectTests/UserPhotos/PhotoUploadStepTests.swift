import Testing
@testable import ZanzarProject

struct PhotoUploadStepTests {
    @Test func sentStepIsSentWhateverTheStatus() {
        #expect(PhotoUploadViewModel.Step.sent(.pending).isSent)
        #expect(PhotoUploadViewModel.Step.sent(.approved).isSent)
    }

    @Test func otherStepsAreNotSent() {
        #expect(!PhotoUploadViewModel.Step.uploading.isSent)
        #expect(!PhotoUploadViewModel.Step.failed(.offline).isSent)
    }

    @Test func failedStepIsFailure() {
        #expect(PhotoUploadViewModel.Step.failed(.offline).isFailure)
    }

    @Test func otherStepsAreNotFailure() {
        #expect(!PhotoUploadViewModel.Step.sent(.pending).isFailure)
        #expect(!PhotoUploadViewModel.Step.preview.isFailure)
    }
}
