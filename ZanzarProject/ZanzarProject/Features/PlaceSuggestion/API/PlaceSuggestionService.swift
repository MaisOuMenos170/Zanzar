import Foundation

protocol PlaceSuggestionServicing: Sendable {
    func currentLocation() async throws -> SuggestedLocation
    /// Typed by hand (nothing to check it against): a person decides.
    func submit(_ suggestion: PlaceSuggestion) async throws
    /// Places on OpenStreetMap that match `query`, near `near` when the user allows it.
    func searchPlaces(query: String, near: SuggestedLocation?) async throws -> [SuggestedPlace]
    /// Suggests a place found by `searchPlaces`; the backend checks it and answers with where it stands.
    func submit(_ place: SuggestedPlace, note: String) async throws -> MySuggestion
    func fetchMine() async throws -> [MySuggestion]
}

struct PlaceSuggestionRequest: Encodable, Sendable {
    let coordinates: Coordinates
    let address: String
    let note: String?

    struct Coordinates: Encodable, Sendable {
        let latitude: Double
        let longitude: Double
    }
}

struct PlaceSuggestionResponse: Decodable, Sendable {
    let id: String

    private enum CodingKeys: String, CodingKey {
        case id = "_id"
    }
}

final class PlaceSuggestionService: PlaceSuggestionServicing {
    private let client: NetworkClient
    private let locationService: LocationMapServicing
    private let geocoder: PlaceGeocoding

    init(
        client: NetworkClient = URLSessionNetworkClient.shared,
        locationService: LocationMapServicing = LocationMapService(),
        geocoder: PlaceGeocoding = MapKitPlaceGeocoder()
    ) {
        self.client = client
        self.locationService = locationService
        self.geocoder = geocoder
    }

    func currentLocation() async throws -> SuggestedLocation {
        let position = try await locationService.currentUserLocation()
        // A reverse-geocoding failure must not block the suggestion: the position itself is what matters.
        let reverseGeocoded = try? await geocoder.address(for: position.clLocationCoordinate2D)
        try Task.checkCancellation()
        let address = reverseGeocoded.flatMap(Self.nonEmpty)
            ?? SuggestedLocation.coordinateText(latitude: position.latitude, longitude: position.longitude)
        return SuggestedLocation(
            latitude: position.latitude,
            longitude: position.longitude,
            address: Self.truncated(address)
        )
    }

    func submit(_ suggestion: PlaceSuggestion) async throws {
        AppLog.suggestion.info("Submitting place suggestion")
        let note = suggestion.note.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = PlaceSuggestionRequest(
            coordinates: .init(latitude: suggestion.location.latitude, longitude: suggestion.location.longitude),
            address: Self.truncated(suggestion.location.address),
            note: note.isEmpty ? nil : note
        )
        do {
            let _: PlaceSuggestionResponse = try await client.send(
                path: "place-suggestions",
                method: .post,
                body: request
            )
            AppLog.suggestion.info("Place suggestion submitted successfully")
        } catch {
            AppLog.suggestion.error("Place suggestion request failed", error: error)
            throw error
        }
    }

    func searchPlaces(query: String, near: SuggestedLocation?) async throws -> [SuggestedPlace] {
        var queryItems = [URLQueryItem(name: "q", value: query)]
        if let near {
            queryItems.append(URLQueryItem(name: "lat", value: String(near.latitude)))
            queryItems.append(URLQueryItem(name: "lng", value: String(near.longitude)))
        }
        let response: [SuggestedPlaceAPIResponse] = try await client.get(
            path: "place-suggestions/search",
            queryItems: queryItems
        )
        return response.compactMap(\.suggestedPlace)
    }

    func submit(_ place: SuggestedPlace, note: String) async throws -> MySuggestion {
        AppLog.suggestion.info("Submitting suggestion of an OpenStreetMap place")
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = OSMPlaceSuggestionRequest(
            osmType: place.osmType,
            osmId: place.osmID,
            note: trimmed.isEmpty ? nil : trimmed
        )
        do {
            let response: MySuggestionAPIResponse = try await client.send(
                path: "place-suggestions",
                method: .post,
                body: request
            )
            AppLog.suggestion.info("Suggestion answered with status \(response.status)")
            return response.mySuggestion
        } catch {
            AppLog.suggestion.error("Place suggestion request failed", error: error)
            throw error
        }
    }

    func fetchMine() async throws -> [MySuggestion] {
        let response: [MySuggestionAPIResponse] = try await client.get(path: "place-suggestions")
        return response.map(\.mySuggestion)
    }

    private static func nonEmpty(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func truncated(_ address: String) -> String {
        String(address.prefix(PlaceSuggestionLimits.addressMaxLength))
    }
}
