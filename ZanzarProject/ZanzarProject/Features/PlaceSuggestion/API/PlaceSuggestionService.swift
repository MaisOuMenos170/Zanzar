import Foundation

protocol PlaceSuggestionServicing: Sendable {
    func currentLocation() async throws -> SuggestedLocation
    func resolveLocation(query: String, near location: SuggestedLocation?) async throws -> SuggestedLocation
    func submit(_ suggestion: PlaceSuggestion) async throws
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

    func resolveLocation(query: String, near location: SuggestedLocation?) async throws -> SuggestedLocation {
        let typed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let match = try await geocoder.firstMatch(for: typed, near: location?.clLocationCoordinate2D) else {
            throw PlaceSuggestionError.placeNotFound
        }
        // Keep the typed text (usually the name) and add the address MapKit found.
        let address = match.address == typed ? typed : "\(typed) — \(match.address)"
        return SuggestedLocation(
            latitude: match.latitude,
            longitude: match.longitude,
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

    private static func nonEmpty(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func truncated(_ address: String) -> String {
        String(address.prefix(PlaceSuggestionLimits.addressMaxLength))
    }
}
