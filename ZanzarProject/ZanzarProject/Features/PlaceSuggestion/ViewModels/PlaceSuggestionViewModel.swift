import Foundation
import Observation

/// "Sugerir um lugar": the user searches Apple Maps by name or address (the search runs by itself a moment after
/// they stop typing) and picks a result. Whatever the result
/// lacks (its name, its address) is asked for in the form, so every suggestion leaves with a name, an address
/// and a position.
@Observable
final class PlaceSuggestionViewModel {
    /// What the user chose in the results.
    enum Selection: Equatable {
        case none
        case place(SuggestedPlace)
        /// Nothing in the results is the place (or there were no results): name and address are typed.
        case notFound
    }

    /// Long enough to skip the keystrokes of a word being typed, short enough to feel immediate. Apple Maps
    /// throttles apps that search on every letter.
    static let defaultDebounce: Duration = .milliseconds(500)

    private let service: PlaceSuggestionServicing
    private let debounce: Duration
    private var searchTask: Task<Void, Never>?
    /// Tells a search that was replaced by a newer one, so its late answer is thrown away.
    private var searchGeneration = 0

    /// What is searched. Exclusive to the search: the name and the address have fields of their own.
    var query = "" {
        didSet {
            guard query != oldValue else { return }
            scheduleSearch(afterDebounce: true)
        }
    }
    var searchNearMe = true
    /// Optional.
    var note = ""
    /// Asked for when the place chosen has no name (or none was found).
    var customName = ""
    /// Asked for when the place chosen has no address (or none was found); looked up on Apple Maps to get its position.
    var customAddress = "" {
        didSet {
            if customAddress != oldValue { addressErrorMessage = nil }
        }
    }

    private(set) var results: [SuggestedPlace] = []
    private(set) var selection: Selection = .none
    private(set) var hasSearched = false
    private(set) var isSearching = false
    private(set) var searchErrorMessage: String?
    /// The typed address could not be placed on the map.
    private(set) var addressErrorMessage: String?

    private(set) var currentLocation: SuggestedLocation?
    private(set) var isResolvingLocation = false
    private(set) var isSubmitting = false
    private(set) var locationErrorMessage: String?
    private(set) var outcome: PlaceSuggestionOutcome?
    /// The address put in the search field by "use my location", so switching to another place can take it out
    /// again without touching what the user typed.
    private var prefilledAddress: String?

    init(
        service: PlaceSuggestionServicing = PlaceSuggestionService(),
        debounce: Duration = PlaceSuggestionViewModel.defaultDebounce
    ) {
        self.service = service
        self.debounce = debounce
    }

    var trimmedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedName: String {
        customName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedAddress: String {
        customAddress.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var selectedPlace: SuggestedPlace? {
        if case .place(let place) = selection { return place }
        return nil
    }

    var isManualEntry: Bool {
        selection == .notFound
    }

    /// The form shows a name field: the place has no name yet.
    var needsName: Bool {
        switch selection {
        case .none: false
        case .notFound: true
        case .place(let place): !place.hasName
        }
    }

    /// The form shows an address field: the place has no address yet.
    var needsAddress: Bool {
        switch selection {
        case .none: false
        case .notFound: true
        case .place(let place): !place.hasAddress
        }
    }

    var canSearch: Bool {
        trimmedQuery.count >= PlaceSuggestionLimits.queryMinLength
            && trimmedQuery.count <= PlaceSuggestionLimits.queryMaxLength
    }

    /// Needs a place and whatever it lacks. The note is optional.
    var canSubmit: Bool {
        guard !isSubmitting, selection != .none, trimmedNote.count <= PlaceSuggestionLimits.noteMaxLength
        else { return false }

        if needsName, trimmedName.isEmpty || trimmedName.count > PlaceSuggestionLimits.nameMaxLength {
            return false
        }
        if needsAddress, trimmedAddress.isEmpty || trimmedAddress.count > PlaceSuggestionLimits.addressMaxLength {
            return false
        }
        return true
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

    /// "Usar minha localização": searches near the user and offers their current address in the search field.
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

    /// Puts the address in the empty search field once the position is known. Never overwrites what was typed.
    func fillQueryWithCurrentAddress() {
        guard searchNearMe, trimmedQuery.isEmpty, let location = currentLocation else { return }
        // Without a street address the lookup falls back to the coordinates, which is no use in a search field.
        let address = location.address
        guard address != SuggestedLocation.coordinateText(latitude: location.latitude, longitude: location.longitude)
        else { return }
        query = address
        prefilledAddress = address
    }

    /// Searches right away, skipping the pause for typing (the keyboard's search key).
    func submitSearch() {
        scheduleSearch(afterDebounce: false)
    }

    /// Waits for the search that is pending, for callers that need the results (tests).
    func waitForSearch() async {
        await searchTask?.value
    }

    private func scheduleSearch(afterDebounce: Bool) {
        searchTask?.cancel()
        searchTask = nil
        searchGeneration += 1

        guard canSearch else {
            clearSearch()
            return
        }

        let pause = afterDebounce ? debounce : .zero
        searchTask = Task { [weak self] in
            if pause > .zero {
                try? await Task.sleep(for: pause)
            }
            guard !Task.isCancelled else { return }
            await self?.search()
        }
    }

    /// The text is too short to search: no results, no chosen place, no fields asked for.
    private func clearSearch() {
        isSearching = false
        results = []
        hasSearched = false
        searchErrorMessage = nil
        selection = .none
        customName = ""
        customAddress = ""
    }

    private func search() async {
        guard canSearch else { return }
        let generation = searchGeneration
        isSearching = true
        searchErrorMessage = nil
        selection = .none
        customName = ""
        customAddress = ""
        defer {
            if generation == searchGeneration { isSearching = false }
        }
        do {
            let found = try await service.searchPlaces(query: trimmedQuery, near: nearbyLocation)
            guard generation == searchGeneration else { return }
            results = found
            hasSearched = true
            // Nothing found: the user fills in the place by hand.
            if found.isEmpty { enterManually() }
        } catch {
            guard generation == searchGeneration, !PlaceSuggestionErrorMapper.isCancellation(error) else { return }
            results = []
            hasSearched = false
            searchErrorMessage = PlaceSuggestionErrorMapper.searchMessage()
        }
    }

    func select(_ place: SuggestedPlace) {
        selection = .place(place)
        addressErrorMessage = nil
    }

    /// For a place Apple Maps does not have: the name (what was searched, to start with) and the address are typed.
    func enterManually() {
        selection = .notFound
        addressErrorMessage = nil
        if trimmedName.isEmpty { customName = trimmedQuery }
    }

    @discardableResult
    func submit() async -> Bool {
        guard canSubmit else { return false }
        isSubmitting = true
        addressErrorMessage = nil
        defer { isSubmitting = false }
        do {
            guard let suggestion = try await makeSuggestion() else {
                addressErrorMessage = L10n.string("placeSuggestion.error.addressNotFound")
                return false
            }
            try await service.submit(suggestion)
            // The backend takes this shape of request for a person to review, so there is no instant verdict.
            outcome = .success
            return true
        } catch {
            guard !PlaceSuggestionErrorMapper.isCancellation(error) else { return false }
            outcome = .failure(message: PlaceSuggestionErrorMapper.submitMessage(for: error))
            return false
        }
    }

    // MARK: - Private

    /// The position of the user, when they asked to search near it.
    private var nearbyLocation: SuggestedLocation? {
        searchNearMe ? currentLocation : nil
    }

    /// The suggestion with a name, an address and a position. `nil` when an address typed by hand could not be
    /// placed on the map and there is no other position to use.
    private func makeSuggestion() async throws -> PlaceSuggestion? {
        let place = selectedPlace
        let name = place?.name ?? trimmedName

        if let place, let address = place.address {
            let location = SuggestedLocation(latitude: place.latitude, longitude: place.longitude, address: address)
            return PlaceSuggestion(name: name, location: location, note: trimmedNote)
        }

        // The address was typed: Apple Maps gives its position and its proper form.
        if let found = try await service.resolveAddress(trimmedAddress, near: nearbyLocation) {
            let location = SuggestedLocation(
                latitude: found.latitude,
                longitude: found.longitude,
                address: found.address ?? trimmedAddress
            )
            return PlaceSuggestion(name: name, location: location, note: trimmedNote)
        }

        // A named place has its own position even when its address is not on the map.
        guard let place else { return nil }
        let location = SuggestedLocation(latitude: place.latitude, longitude: place.longitude, address: trimmedAddress)
        return PlaceSuggestion(name: name, location: location, note: trimmedNote)
    }
}
