import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("PhotoTermsViewModel")
struct PhotoTermsViewModelTests {
    @Test("cannot submit without a birth date and both agreements")
    func requiresEverything() {
        let viewModel = PhotoTermsViewModel(service: MockUserPhotosService(), userIDProvider: { "user-1" })
        #expect(!viewModel.canSubmit)
        viewModel.birthDate = Date(timeIntervalSince1970: 0)
        viewModel.acceptsTerms = true
        #expect(!viewModel.canSubmit)
        viewModel.acceptsAIAnalysis = true
        #expect(viewModel.canSubmit)
    }

    @Test("an adult who accepts can upload")
    func adultAccepts() async {
        let service = MockUserPhotosService()
        let viewModel = PhotoTermsViewModel(service: service, userIDProvider: { "user-1" })
        viewModel.birthDate = Date(timeIntervalSince1970: 0)
        viewModel.acceptsTerms = true
        viewModel.acceptsAIAnalysis = true

        #expect(await viewModel.submit())
        #expect(service.acceptedBirthDates.count == 1)
    }

    @Test("a minor is told and cannot continue")
    func minorIsRefused() async {
        let service = MockUserPhotosService()
        service.acceptResult = .success(PhotoTermsStatus(hasAcceptedCurrentTerms: false, isAdult: false))
        let viewModel = PhotoTermsViewModel(service: service, userIDProvider: { "user-1" })
        viewModel.birthDate = .now
        viewModel.acceptsTerms = true
        viewModel.acceptsAIAnalysis = true

        #expect(await viewModel.submit() == false)
        #expect(viewModel.isUnderage)
    }
}
