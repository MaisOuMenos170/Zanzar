import Foundation
import Observation

/// Reporting a photo of someone else, optionally blocking its author too.
@Observable
final class ReportPhotoViewModel {
    let photoID: String
    let placeID: String
    var reason: PhotoReportReason?
    var note = ""
    var alsoBlocksAuthor = false
    private(set) var isSubmitting = false
    private(set) var didFinish = false
    var errorMessage: String?

    static let maximumNoteLength = 500

    private let service: UserPhotosServicing
    private let userIDProvider: @Sendable () -> String?

    init(
        photoID: String,
        placeID: String,
        service: UserPhotosServicing = UserPhotosService(),
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.userID }
    ) {
        self.photoID = photoID
        self.placeID = placeID
        self.service = service
        self.userIDProvider = userIDProvider
    }

    var canSubmit: Bool { reason != nil && !isSubmitting }

    func submit() async {
        guard let reason, let userID = userIDProvider() else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        errorMessage = nil
        let trimmed = String(note.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.maximumNoteLength))
        do {
            let note = trimmed.isEmpty ? nil : trimmed
            try await service.reportPhoto(photoID, placeID: placeID, reason: reason, note: note)
            if alsoBlocksAuthor {
                try await service.blockAuthor(ofPhoto: photoID, userID: userID)
            }
            didFinish = true
        } catch {
            errorMessage = APIError.rateLimitedMessage(for: error) ?? L10n.string("userPhotos.report.error.message")
        }
    }

    /// Blocking without reporting, from the photo's menu.
    func blockOnly() async {
        guard let userID = userIDProvider() else { return }
        do {
            try await service.blockAuthor(ofPhoto: photoID, userID: userID)
            didFinish = true
        } catch {
            errorMessage = L10n.string("userPhotos.report.error.message")
        }
    }
}
