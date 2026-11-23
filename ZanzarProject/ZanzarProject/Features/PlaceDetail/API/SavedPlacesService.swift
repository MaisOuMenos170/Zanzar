import Foundation

/// The places the user bookmarked (`/user/:id/saved-places`): the list itself, and putting a place on it or
/// taking it off.
protocol SavedPlacesServicing: Sendable {
    /// The saved places, the most recently saved first.
    func fetchSavedPlaces(userID: String) async throws -> [SavedPlace]
    func savedPlaceIDs(userID: String) async throws -> Set<String>
    /// Idempotent: saving a place that is already saved succeeds. Throws `APIError.httpStatus(409, …)` at the limit.
    func save(placeID: String, userID: String) async throws
    /// Idempotent: removing a place that is not saved succeeds.
    func remove(placeID: String, userID: String) async throws
}

private struct SavedPlaceAPIResponse: Decodable, Sendable {
    let placeId: String
    /// Only the list sends the rest; the response of saving a place carries just what it needs.
    let savedAt: String?
    let placeName: String?
    let imageUrl: String?

    func makeSavedPlace() -> SavedPlace {
        SavedPlace(
            placeID: placeId,
            name: placeName,
            // The app only loads photos from `https`.
            imageURL: imageUrl.flatMap(URL.init(string:)).flatMap { $0.scheme == "https" ? $0 : nil },
            savedAt: savedAt.flatMap(APIDate.parse) ?? .distantPast
        )
    }
}

private struct SavePlaceRequest: Encodable, Sendable {
    let placeId: String
}

final class SavedPlacesService: SavedPlacesServicing {
    private let client: NetworkClient

    init(client: NetworkClient = URLSessionNetworkClient.shared) {
        self.client = client
    }

    func fetchSavedPlaces(userID: String) async throws -> [SavedPlace] {
        let places: [SavedPlaceAPIResponse] = try await client.get(path: "user/\(userID)/saved-places")
        return places.map { $0.makeSavedPlace() }
    }

    func savedPlaceIDs(userID: String) async throws -> Set<String> {
        let places = try await fetchSavedPlaces(userID: userID)
        return Set(places.map(\.placeID))
    }

    func save(placeID: String, userID: String) async throws {
        let _: SavedPlaceAPIResponse = try await client.send(
            path: "user/\(userID)/saved-places",
            method: .post,
            body: SavePlaceRequest(placeId: placeID)
        )
        AppLog.placeDetail.info("Saved place placeId=\(placeID)")
    }

    func remove(placeID: String, userID: String) async throws {
        do {
            try await client.sendWithoutResponse(path: "user/\(userID)/saved-places/\(placeID)", method: .delete)
        } catch APIError.httpStatus(404, _) {
            // Already off the list, which is what the user asked for.
        }
        AppLog.placeDetail.info("Removed saved place placeId=\(placeID)")
    }
}
