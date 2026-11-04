import Foundation
import Observation

@Observable
final class PlaceSuggestionViewModel {
    private let service: PlaceSuggestionServicing

    var mode: PlaceSuggestionLocationMode = .currentLocation
    var placeQuery = ""
    var note = ""

    private(set) var currentLocation: SuggestedLocation?
    private(set) var isResolvingLocation = false
    private(set) var isSubmitting = false
    private(set) var locationErrorMessage: String?
    private(set) var outcome: PlaceSuggestionOutcome?

    init(service: PlaceSuggestionServicing = PlaceSuggestionService()) {
        self.service = service
    }

    var trimmedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedQuery: String {
        placeQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The note is required by the form (per the design) although the backend treats it as optional.
    var canSubmit: Bool {
        guard !isSubmitting,
              !trimmedNote.isEmpty,
              trimmedNote.count <= PlaceSuggestionLimits.noteMaxLength
        else { return false }

        switch mode {
        case .currentLocation:
            return currentLocation != nil
        case .otherPlace:
            return !trimmedQuery.isEmpty && trimmedQuery.count <= PlaceSuggestionLimits.addressMaxLength
        }
    }

    /// Looks up the position once; calling it again after a failure retries.
    func loadCurrentLocation() async {
        guard mode == .currentLocation, currentLocation == nil, !isResolvingLocation else { return }
        isResolvingLocation = true
        locationErrorMessage = nil
        defer { isResolvingLocation = false }
        do {
            currentLocation = try await service.currentLocation()
        } catch {
            guard !PlaceSuggestionErrorMapper.isCancellation(error) else { return }
            locationErrorMessage = PlaceSuggestionErrorMapper.locationMessage(for: error)
        }
    }

    @discardableResult
    func submit() async -> Bool {
        guard canSubmit else { return false }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let location = try await locationForSubmission()
            try await service.submit(PlaceSuggestion(location: location, note: trimmedNote))
            outcome = .success
            return true
        } catch {
            guard !PlaceSuggestionErrorMapper.isCancellation(error) else { return false }
            outcome = .failure(message: PlaceSuggestionErrorMapper.submitMessage(for: error))
            return false
        }
    }

    private func locationForSubmission() async throws -> SuggestedLocation {
        switch mode {
        case .currentLocation:
            if let currentLocation { return currentLocation }
            return try await service.currentLocation()
        case .otherPlace:
            return try await service.resolveLocation(query: trimmedQuery, near: currentLocation)
        }
    }
}
