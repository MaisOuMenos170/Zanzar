import Foundation
import Observation

@Observable
final class EditNameViewModel {
    /// The backend accepts names of 3 to 30 characters: letters, digits and underscore.
    static let lengthRange = 3...30

    static func isValid(_ name: String) -> Bool {
        lengthRange.contains(name.count) && name.wholeMatch(of: /[A-Za-z0-9_]+/) != nil
    }

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
        self.name = ""
        self.service = service
        self.userIDProvider = userIDProvider
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool {
        !isSaving
            && Self.isValid(trimmedName)
            && trimmedName != currentName
    }

    var showsInvalidHint: Bool {
        !trimmedName.isEmpty && !Self.isValid(trimmedName)
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
            errorMessage = Self.message(for: error)
            return false
        }
    }

    private static func message(for error: Error) -> String {
        if let rateLimited = APIError.rateLimitedMessage(for: error) {
            return rateLimited
        }
        // The backend answers 409 when another account has the name.
        if case .httpStatus(409, _)? = error as? APIError {
            return L10n.string("profile.editName.takenError")
        }
        return L10n.string("profile.editName.errorAlert.title")
    }
}
