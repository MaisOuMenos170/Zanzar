import CoreLocation
import Foundation
import Observation

/// The share sheet: works out which place a shared address or map link is, lets the person confirm it and sends
/// it as a suggestion, the same way "Sugerir um lugar" does
@MainActor
@Observable
final class PlaceShareViewModel {
    enum Phase: Equatable {
        /// Following the link and looking the place up.
        case reading
        case ready
        /// Nothing in what was shared says where the place is.
        case unreadable
        /// The place is outside Curitiba and its region, where suggestions are accepted.
        case outsideArea
        case signedOut
        case submitting
        case done(PlaceSuggestionOutcome)
    }

    /// A place this close to the shared position is taken to be the one meant.
    static let autoSelectRadiusMeters: CLLocationDistance = 150

    private(set) var phase: Phase = .reading
    private(set) var hint = SharedPlaceHint()
    private(set) var candidates: [SuggestedPlace] = []
    private(set) var selectedPlace: SuggestedPlace?
    private(set) var isManualChosen = false
    private(set) var searchErrorMessage: String?
    private(set) var submitErrorMessage: String?
    var note = ""

    private var hasLoaded = false
    private let texts: [String]
    private let urls: [URL]
    private let service: PlaceSuggestionServicing
    private let resolver: MapLinkResolver
    private let geocoder: PlaceGeocoding
    private let isSignedIn: () -> Bool

    init(
        texts: [String],
        urls: [URL],
        service: PlaceSuggestionServicing,
        resolver: MapLinkResolver = MapLinkResolver(),
        geocoder: PlaceGeocoding = MapKitPlaceGeocoder(),
        isSignedIn: @escaping () -> Bool
    ) {
        self.texts = texts
        self.urls = urls
        self.service = service
        self.resolver = resolver
        self.geocoder = geocoder
        self.isSignedIn = isSignedIn
    }

    // MARK: - What the sheet shows

    /// What goes to the team when no place on the map is chosen: the address and, when the link had one, the position.
    var manualLocation: SuggestedLocation? {
        let coordinate = hint.coordinate
        guard let text = hint.address ?? hint.name
                ?? coordinate.map({ SuggestedLocation.coordinateText(latitude: $0.latitude, longitude: $0.longitude) })
        else { return nil }
        return SuggestedLocation(
            latitude: coordinate?.latitude ?? 0,
            longitude: coordinate?.longitude ?? 0,
            address: String(text.prefix(PlaceSuggestionLimits.addressMaxLength))
        )
    }

    var canSubmit: Bool {
        guard phase == .ready else { return false }
        return selectedPlace != nil || (isManualChosen && manualLocation != nil)
    }

    // MARK: - Steps

    /// Runs once: the sheet's `.task` can start again if the view is rebuilt, and that must not undo a send.
    func load() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        guard isSignedIn() else { phase = .signedOut; return }

        let shared = MapLinkParser.read(texts: texts, urls: urls)
        var link: URL?
        if let mapURL = shared.mapURL { link = await resolver.resolve(mapURL) }
        hint = MapLinkParser.hint(link: link, lines: shared.lines)
        guard !hint.isEmpty else { phase = .unreadable; return }

        if let position = hint.coordinate {
            guard ServiceArea.contains(latitude: position.latitude, longitude: position.longitude) else {
                phase = .outsideArea
                return
            }
            if hint.searchText == nil {
                let found = try? await geocoder.address(
                    for: CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude)
                )
                hint.address = found.flatMap(Self.nonEmpty)
                    ?? SuggestedLocation.coordinateText(latitude: position.latitude, longitude: position.longitude)
            }
        }

        await search()
        guard !Task.isCancelled else { return }
        // Nothing on the map to pick: the only way to send it is for the team to look at it.
        isManualChosen = candidates.isEmpty && manualLocation != nil
        phase = .ready
    }

    func select(_ place: SuggestedPlace) {
        selectedPlace = place
        isManualChosen = false
    }

    func chooseManual() {
        selectedPlace = nil
        isManualChosen = true
    }

    func submit() async {
        guard canSubmit else { return }
        phase = .submitting
        submitErrorMessage = nil
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = String(trimmedNote.prefix(PlaceSuggestionLimits.noteMaxLength))
        do {
            if let suggestion = suggestion(note: text) {
                phase = .done(try await service.submit(suggestion))
            }
        } catch {
            if case .httpStatus(401, _)? = error as? APIError {
                phase = .signedOut
            } else if PlaceSuggestionErrorMapper.isCancellation(error) {
                phase = .ready
            } else {
                submitErrorMessage = PlaceSuggestionErrorMapper.submitMessage(for: error)
                phase = .ready
            }
        }
    }

    /// The place the person confirmed, or the shared address and position when none was found on the map.
    private func suggestion(note: String) -> PlaceSuggestion? {
        if let selectedPlace {
            let (latitude, longitude) = (selectedPlace.latitude, selectedPlace.longitude)
            let address = selectedPlace.address ?? hint.address
                ?? SuggestedLocation.coordinateText(latitude: latitude, longitude: longitude)
            let location = SuggestedLocation(
                latitude: selectedPlace.latitude,
                longitude: selectedPlace.longitude,
                address: address
            )
            return PlaceSuggestion(name: selectedPlace.name ?? hint.name ?? "", location: location, note: note)
        }
        guard let location = manualLocation else { return nil }
        return PlaceSuggestion(name: hint.name ?? "", location: location, note: note)
    }

    // MARK: - Looking the place up

    /// By name first, then by address: a name from a link can be one OpenStreetMap writes differently.
    private func search() async {
        let near = hint.coordinate.map {
            SuggestedLocation(latitude: $0.latitude, longitude: $0.longitude, address: hint.address ?? "")
        }
        var queries: [String] = []
        for text in [hint.name, hint.address].compactMap({ $0 }) where !queries.contains(text) { queries.append(text) }

        for text in queries {
            let query = String(text.prefix(PlaceSuggestionLimits.queryMaxLength))
            guard query.count >= PlaceSuggestionLimits.queryMinLength else { continue }
            do {
                let found = try await service.searchPlaces(query: query, near: near)
                guard !found.isEmpty else { continue }
                candidates = sortedByDistance(found)
                selectedPlace = preselected(from: candidates)
                return
            } catch {
                guard !PlaceSuggestionErrorMapper.isCancellation(error) else { return }
                searchErrorMessage = PlaceSuggestionErrorMapper.searchMessage()
                return
            }
        }
    }

    private func sortedByDistance(_ places: [SuggestedPlace]) -> [SuggestedPlace] {
        guard let position = hint.coordinate else { return places }
        return places.sorted { distance(from: position, to: $0) < distance(from: position, to: $1) }
    }

    /// The place at the shared position; with no position, the only one there is.
    private func preselected(from places: [SuggestedPlace]) -> SuggestedPlace? {
        if let position = hint.coordinate {
            return places.first { distance(from: position, to: $0) <= Self.autoSelectRadiusMeters }
        }
        return places.count == 1 ? places.first : nil
    }

    private func distance(from position: SharedPlaceHint.Coordinate, to place: SuggestedPlace) -> CLLocationDistance {
        CLLocation(latitude: position.latitude, longitude: position.longitude)
            .distance(from: CLLocation(latitude: place.latitude, longitude: place.longitude))
    }

    private static func nonEmpty(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
