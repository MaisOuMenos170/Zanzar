import Foundation

protocol PlaceSearchServicing: Sendable {
    /// Places whose name, nickname or address match `query`, nearest to `coordinate` first.
    func searchPlaces(
        query: String,
        near coordinate: UserCoordinate,
        categories: Set<ZanzarPlaceCategory>
    ) async throws -> [MapPlace]
}

/// `GET /places/search`: the backend looks through every place, not only the ones already on the map.
final class PlaceSearchService: PlaceSearchServicing {
    private let client: NetworkClient

    init(client: NetworkClient = URLSessionNetworkClient.shared) {
        self.client = client
    }

    func searchPlaces(
        query: String,
        near coordinate: UserCoordinate,
        categories: Set<ZanzarPlaceCategory>
    ) async throws -> [MapPlace] {
        var queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "lat", value: String(coordinate.latitude)),
            URLQueryItem(name: "lng", value: String(coordinate.longitude))
        ]
        if !categories.isEmpty {
            // Sorted so the same filter always produces the same request.
            let value = categories.map(\.rawValue).sorted().joined(separator: ",")
            queryItems.append(URLQueryItem(name: "categories", value: value))
        }
        do {
            let responses: [PlaceAPIResponse] = try await client.get(path: "places/search", queryItems: queryItems)
            AppLog.map.info("Search returned \(responses.count) places")
            return responses.map(MapPlace.init(response:))
        } catch {
            // The text typed is user data, so it is not logged.
            AppLog.map.error("Failed to search places", error: error)
            throw error
        }
    }
}
