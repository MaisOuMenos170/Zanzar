import Foundation
import Observation

/// The photo terms: the user reads them, declares a birth date and agrees, including to the third-party AI analysis.
@Observable
final class PhotoTermsViewModel {
    var birthDate: Date?
    var acceptsTerms = false
    var acceptsAIAnalysis = false
    private(set) var isSubmitting = false
    private(set) var isUnderage = false
    var errorMessage: String?

    private let service: UserPhotosServicing
    private let userIDProvider: @Sendable () -> String?

    init(
        service: UserPhotosServicing = UserPhotosService(),
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.userID }
    ) {
        self.service = service
        self.userIDProvider = userIDProvider
    }

    var canSubmit: Bool {
        birthDate != nil && acceptsTerms && acceptsAIAnalysis && !isSubmitting
    }

    /// Returns true when the user may now send photos.
    func submit() async -> Bool {
        guard canSubmit, let birthDate, let userID = userIDProvider() else { return false }
        isSubmitting = true
        defer { isSubmitting = false }
        errorMessage = nil
        do {
            let status = try await service.acceptTerms(userID: userID, birthDate: birthDate)
            isUnderage = status.isAdult == false
            return status.canUpload
        } catch {
            errorMessage = APIError.rateLimitedMessage(for: error) ?? L10n.string("userPhotos.terms.error.message")
            return false
        }
    }
}
