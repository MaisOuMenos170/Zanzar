import Foundation

/// The places the user bookmarked (`/user/:id/saved-places`). The place detail only needs to know whether one
/// place is on the list and to put it on or take it off.
protocol SavedPlacesServicing: Sendable {
    func savedPlaceIDs(userID: String) async throws -> Set<String>
    /// Idempotent: saving a place that is already saved succeeds. Throws `APIError.httpStatus(409, …)` at the limit.
    func save(placeID: String, userID: String) async throws
    /// Idempotent: removing a place that is not saved succeeds.
    func remove(placeID: String, userID: String) async throws
}

private struct SavedPlaceAPIResponse: Decodable, Sendable {
    let placeId: String
}

private struct SavePlaceRequest: Encodable, Sendable {
    let placeId: String
}

final class SavedPlacesService: SavedPlacesServicing {
    private let client: NetworkClient

    init(client: NetworkClient = URLSessionNetworkClient.shared) {
        self.client = client
    }

    func savedPlaceIDs(userID: String) async throws -> Set<String> {
        let places: [SavedPlaceAPIResponse] = try await client.get(path: "user/\(userID)/saved-places")
        return Set(places.map(\.placeId))
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
