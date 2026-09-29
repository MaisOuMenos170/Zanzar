import Foundation

protocol PlaceDetailServicing: Sendable {
    func fetchPlaceDetail(for place: MapPlace) async throws -> PlaceDetail
    func checkIn(at placeID: String) async throws -> PlaceDetail
}

struct PlaceDetailRequest: Encodable {
    let placeID: String
}

struct PlaceDetailResponse: Decodable {
    let placeID: String
}

final class PlaceDetailService: PlaceDetailServicing {
    private let client: NetworkClient

    init(client: NetworkClient = URLSessionNetworkClient.shared) {
        self.client = client
    }

    func fetchPlaceDetail(for place: MapPlace) async throws -> PlaceDetail {
        // TODO: replace with real endpoint when backend is ready
        try await Task.sleep(for: .milliseconds(300))
        return PlaceDetail.mock(for: place)
    }

    func checkIn(at placeID: String) async throws -> PlaceDetail {
        // TODO: replace with real endpoint when backend is ready
        try await Task.sleep(for: .milliseconds(200))
        var detail = PlaceDetail.mock(
            for: MapPlace(
                id: placeID,
                name: "",
                latitude: 0,
                longitude: 0,
                category: .unknown,
                distanceMeters: 1300
            )
        )
        detail.hasCheckedIn = true
        return detail
    }
}
