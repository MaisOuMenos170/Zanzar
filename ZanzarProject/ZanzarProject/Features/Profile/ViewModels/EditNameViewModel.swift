import Foundation
import Observation

/// The "Editar nome" card: the name being typed and sending it.
@Observable
final class EditNameViewModel {
    /// The backend accepts names of 3 to 30 characters.
    static let lengthRange = 3...30

    var name: String
    private(set) var isSaving = false
    private(set) var didSave = false
    private(set) var errorMessage: String?

    private let currentName: String
    private let service: ProfileServicing
    private let userIDProvider: @Sendable () -> String?

    init(
        currentName: String,
        service: ProfileServicing = ProfileService(),
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.userID }
    ) {
        self.currentName = currentName
        // Starts empty: the field shows its placeholder and the user types the new name.
        self.name = ""
        self.service = service
        self.userIDProvider = userIDProvider
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The button works once the name is filled in, fits what the backend accepts and is not the one already in use.
    var canSave: Bool {
        !isSaving
            && Self.lengthRange.contains(trimmedName.count)
            && trimmedName != currentName
    }

    @discardableResult
    func save() async -> Bool {
        guard canSave, let userID = userIDProvider() else { return false }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            try await service.updateName(userID: userID, name: trimmedName)
            didSave = true
            return true
        } catch is CancellationError {
            return false
        } catch {
            errorMessage = APIError.rateLimitedMessage(for: error) ?? L10n.string("profile.editName.errorAlert.title")
            return false
        }
    }
}
