import Foundation

/// Finds the place a link points to when the app has not loaded it (a link can name a place far from the user).
protocol PlaceLinkResolving: Sendable {
    func place(id: String) async throws -> MapPlace
}

final class PlaceLinkService: PlaceLinkResolving {
    private let client: NetworkClient

    init(client: NetworkClient = URLSessionNetworkClient.shared) {
        self.client = client
    }

    func place(id: String) async throws -> MapPlace {
        let encodedID = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
        let response: PlaceDetailAPIResponse = try await client.get(path: "places/\(encodedID)")
        return MapPlace(
            id: response.placeId,
            name: response.name,
            nickname: response.nickname,
            latitude: response.geometry.location.lat,
            longitude: response.geometry.location.lng,
            category: ZanzarPlaceCategory(rawCategory: response.zanzar.category),
            distanceMeters: response.distanceMeters
        )
    }
}
