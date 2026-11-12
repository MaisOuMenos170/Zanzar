import Foundation
import Observation

@Observable
final class PlaceSuggestionViewModel {
    private let service: PlaceSuggestionServicing

    var query = ""
    var searchNearMe = true
    var note = ""

    private(set) var results: [SuggestedPlace] = []
    private(set) var selectedPlace: SuggestedPlace?
    /// The user could not find the place and chose to send what they typed to the team.
    private(set) var isManualEntry = false
    private(set) var hasSearched = false
    private(set) var isSearching = false
    private(set) var searchErrorMessage: String?

    private(set) var currentLocation: SuggestedLocation?
    private(set) var isResolvingLocation = false
    private(set) var isSubmitting = false
    private(set) var locationErrorMessage: String?
    private(set) var outcome: PlaceSuggestionOutcome?
    /// The address put in the name field by "use my location", so switching to another place can take it out
    /// again without touching what the user typed.
    private var prefilledAddress: String?

    init(service: PlaceSuggestionServicing = PlaceSuggestionService()) {
        self.service = service
    }

    var trimmedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSearch: Bool {
        !isSearching && trimmedQuery.count >= PlaceSuggestionLimits.queryMinLength
            && trimmedQuery.count <= PlaceSuggestionLimits.queryMaxLength
    }

    /// The note is required by the form (per the design) although the backend treats it as optional.
    var canSubmit: Bool {
        guard !isSubmitting,
              !trimmedNote.isEmpty,
              trimmedNote.count <= PlaceSuggestionLimits.noteMaxLength
        else { return false }

        if selectedPlace != nil { return true }
        return isManualEntry
            && !trimmedQuery.isEmpty
            && trimmedQuery.count <= PlaceSuggestionLimits.addressMaxLength
    }

    /// Looks up the position once, to search near the user; calling it again after a failure retries.
    func loadCurrentLocation() async {
        guard searchNearMe, currentLocation == nil, !isResolvingLocation else { return }
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

    /// "Usar minha localização": searches near the user and offers their current address in the name field.
    func useCurrentLocation() {
        searchNearMe = true
        fillQueryWithCurrentAddress()
    }

    /// "Outro lugar": the field starts empty again, unless the user already wrote something of their own.
    func useAnotherPlace() {
        searchNearMe = false
        if let prefilledAddress, query == prefilledAddress {
            query = ""
        }
        prefilledAddress = nil
    }

    /// Puts the address in the empty name field once the position is known. Never overwrites what was typed.
    func fillQueryWithCurrentAddress() {
        guard searchNearMe, trimmedQuery.isEmpty, let location = currentLocation else { return }
        // Without a street address the lookup falls back to the coordinates, which is no use in a name field.
        let address = location.address
        guard address != SuggestedLocation.coordinateText(latitude: location.latitude, longitude: location.longitude)
        else { return }
        query = address
        prefilledAddress = address
    }

    func search() async {
        guard canSearch else { return }
        isSearching = true
        searchErrorMessage = nil
        selectedPlace = nil
        isManualEntry = false
        defer { isSearching = false }
        do {
            results = try await service.searchPlaces(query: trimmedQuery, near: searchNearMe ? currentLocation : nil)
            hasSearched = true
        } catch {
            guard !PlaceSuggestionErrorMapper.isCancellation(error) else { return }
            results = []
            hasSearched = false
            searchErrorMessage = PlaceSuggestionErrorMapper.searchMessage(for: error)
        }
    }

    func select(_ place: SuggestedPlace) {
        selectedPlace = place
        isManualEntry = false
    }

    /// For a place OpenStreetMap does not have: what was typed goes to the team, who add it by hand.
    func enterManually() {
        selectedPlace = nil
        isManualEntry = true
    }

    @discardableResult
    func submit() async -> Bool {
        guard canSubmit else { return false }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            if let selectedPlace {
                let suggestion = try await service.submit(selectedPlace, note: trimmedNote)
                outcome = Self.outcome(for: suggestion)
            } else {
                let location = manualLocation()
                try await service.submit(PlaceSuggestion(location: location, note: trimmedNote))
                outcome = .success
            }
            return true
        } catch {
            guard !PlaceSuggestionErrorMapper.isCancellation(error) else { return false }
            outcome = .failure(message: PlaceSuggestionErrorMapper.submitMessage(for: error))
            return false
        }
    }

    /// What the user is told once the backend has checked the suggestion.
    static func outcome(for suggestion: MySuggestion) -> PlaceSuggestionOutcome {
        switch suggestion.status {
        case .approved:
            .published(placeName: suggestion.displayName)
        case .rejected:
            .refused(suggestion.decisionReason ?? .other(""))
        case .pending, .needsReview:
            .success
        }
    }

    /// The typed text with the user's position when it is known, so the team can find the place on a map.
    private func manualLocation() -> SuggestedLocation {
        let known = searchNearMe ? currentLocation : nil
        return SuggestedLocation(
            latitude: known?.latitude ?? 0,
            longitude: known?.longitude ?? 0,
            address: trimmedQuery
        )
    }
}
