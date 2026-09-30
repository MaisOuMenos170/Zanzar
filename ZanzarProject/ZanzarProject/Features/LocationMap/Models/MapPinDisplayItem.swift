import CoreLocation
import Foundation

struct MapPinCluster: Identifiable, Equatable, Sendable {
    let id: String
    let places: [MapPlace]
    let latitude: Double
    let longitude: Double

    var count: Int { places.count }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(cellColumn: Int, cellRow: Int, places: [MapPlace]) {
        precondition(!places.isEmpty, "A cluster must contain at least one place.")

        self.places = places
        id = "cluster-\(cellColumn)-\(cellRow)"
        latitude = places.map(\.latitude).reduce(0, +) / Double(places.count)
        longitude = places.map(\.longitude).reduce(0, +) / Double(places.count)
    }
}

enum MapPinDisplayItem: Identifiable, Equatable, Sendable {
    case place(MapPlace)
    case cluster(MapPinCluster)

    var id: String {
        switch self {
        case .place(let place):
            place.id
        case .cluster(let cluster):
            cluster.id
        }
    }

    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .place(let place):
            place.coordinate
        case .cluster(let cluster):
            cluster.coordinate
        }
    }
}
