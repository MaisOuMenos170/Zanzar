import CoreLocation
import Foundation

protocol PlaceSuggestionServicing: Sendable {
    func currentLocation() async throws -> SuggestedLocation
    /// Always has a position. The backend checks the place itself and answers at once: added, refused, or waiting
    /// for a person.
    func submit(_ suggestion: PlaceSuggestion) async throws -> PlaceSuggestionOutcome
    /// Places Apple Maps finds for a name or an address, near `near` when the user allows it.
    func searchPlaces(query: String, near: SuggestedLocation?) async throws -> [SuggestedPlace]
    /// The position and the written form of an address the user typed; `nil` when Apple Maps cannot place it.
    func resolveAddress(_ text: String, near: SuggestedLocation?) async throws -> SuggestedPlace?
    func fetchMine() async throws -> [MySuggestion]
}

struct PlaceSuggestionRequest: Encodable, Sendable {
    /// Left out when the user gave none; the backend then sends the suggestion to a person.
    let name: String?
    let coordinates: Coordinates
    let address: String
    let note: String?

    struct Coordinates: Encodable, Sendable {
        let latitude: Double
        let longitude: Double
    }
}

/// Where the user is now. It is all the service needs of the map's location service, so the share extension can
/// use the service without compiling the map (`PlaceSuggestionService+LocationMap.swift` connects the two).
typealias UserPositionProvider = @Sendable () async throws -> (latitude: Double, longitude: Double)

final class PlaceSuggestionService: PlaceSuggestionServicing {
    private let client: NetworkClient
    private let userPosition: UserPositionProvider
    private let geocoder: PlaceGeocoding

    init(
        client: NetworkClient = URLSessionNetworkClient.shared,
        userPosition: @escaping UserPositionProvider,
        geocoder: PlaceGeocoding = MapKitPlaceGeocoder()
    ) {
        self.client = client
        self.userPosition = userPosition
        self.geocoder = geocoder
    }

    func currentLocation() async throws -> SuggestedLocation {
        let position = try await userPosition()
        // A reverse-geocoding failure must not block the suggestion: the position itself is what matters.
        let reverseGeocoded = try? await geocoder.address(
            for: CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude)
        )
        try Task.checkCancellation()
        let address = reverseGeocoded.flatMap(Self.nonEmpty)
            ?? SuggestedLocation.coordinateText(latitude: position.latitude, longitude: position.longitude)
        return SuggestedLocation(
            latitude: position.latitude,
            longitude: position.longitude,
            address: Self.truncated(address)
        )
    }

    func submit(_ suggestion: PlaceSuggestion) async throws -> PlaceSuggestionOutcome {
        AppLog.suggestion.info("Submitting place suggestion")
        let note = suggestion.note.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = PlaceSuggestionRequest(
            name: suggestion.requestName,
            coordinates: .init(latitude: suggestion.location.latitude, longitude: suggestion.location.longitude),
            address: suggestion.addressText,
            note: note.isEmpty ? nil : note
        )
        do {
            let response: MySuggestionAPIResponse = try await client.send(
                path: "place-suggestions",
                method: .post,
                body: request
            )
            let outcome = PlaceSuggestionOutcome(response.mySuggestion)
            AppLog.suggestion.info("Place suggestion submitted successfully")
            return outcome
        } catch {
            AppLog.suggestion.error("Place suggestion request failed", error: error)
            throw error
        }
    }

    func searchPlaces(query: String, near: SuggestedLocation?) async throws -> [SuggestedPlace] {
        try await geocoder.places(
            matching: query,
            near: near?.clLocationCoordinate2D,
            includingPointsOfInterest: true
        )
    }

    func resolveAddress(_ text: String, near: SuggestedLocation?) async throws -> SuggestedPlace? {
        try await geocoder.places(
            matching: text,
            near: near?.clLocationCoordinate2D,
            includingPointsOfInterest: false
        ).first
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
