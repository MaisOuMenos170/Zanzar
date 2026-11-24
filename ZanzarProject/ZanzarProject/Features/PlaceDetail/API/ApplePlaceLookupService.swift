import Foundation
import MapKit

protocol ApplePlaceLookingUp {
    /// The Apple Maps place for `place`, whose card shows Apple's photos of it; `nil` when Apple does not
    /// know the place or no result is a safe match.
    func mapItem(for place: MapPlace) async throws -> MKMapItem?
}

/// Finds our places in Apple Maps by name around their coordinate. Apple's photos are never stored: the app
/// only keeps the `MKMapItem` for this session and hands it to Apple's place card.
final class ApplePlaceLookupService: ApplePlaceLookingUp {
    static let shared = ApplePlaceLookupService()

    /// Search radius around the place, larger than the match distance so a park pinned far away still comes back.
    private static let searchRadiusMeters: CLLocationDistance = 1_000

    /// Results by place id, including "not found", so reopening a place does not search again.
    private var cache: [String: MKMapItem?] = [:]

    func mapItem(for place: MapPlace) async throws -> MKMapItem? {
        if let cached = cache[place.id] {
            return cached
        }

        let coordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = ApplePlaceMatcher.searchQuery(for: place.name)
        request.resultTypes = .pointOfInterest
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: Self.searchRadiusMeters,
            longitudinalMeters: Self.searchRadiusMeters
        )

        let items: [MKMapItem]
        do {
            items = try await MKLocalSearch(request: request).start().mapItems
        } catch let error as MKError where error.code == .placemarkNotFound {
            items = []
        }

        let candidates = items.map {
            ApplePlaceCandidate(
                name: $0.name ?? "",
                latitude: $0.location.coordinate.latitude,
                longitude: $0.location.coordinate.longitude
            )
        }
        let match = ApplePlaceMatcher.bestMatchIndex(
            names: [place.name, place.nickname].compactMap(\.self),
            latitude: place.latitude,
            longitude: place.longitude,
            category: place.category,
            candidates: candidates
        ).map { items[$0] }

        if match == nil {
            AppLog.placeDetail.info("No Apple Maps match among \(items.count) results")
        }
        // `.some` keeps a "not found" in the cache; assigning `nil` would remove the key.
        cache[place.id] = .some(match)
        return match
    }
}
