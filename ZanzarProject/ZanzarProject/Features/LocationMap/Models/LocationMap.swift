import CoreLocation
import Foundation

/// The user's current position on the map — the domain shape the View/ViewModel work with,
/// distinct from CoreLocation's `CLLocation` (which the Service layer deals with).
struct UserCoordinate: Hashable, Sendable {
    let latitude: Double
    let longitude: Double

    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

#if DEBUG
enum DevLocation {
    /// PUC-PR (Campus Curitiba) — fixed simulator position for local map testing.
    static let pucPr = UserCoordinate(latitude: -25.4298844, longitude: -49.2719424)
}
#endif

enum ZanzarPlaceCategory: String, Sendable {
    case museum
    case park
    case restaurant
    case bar
    case cafe
    case historic
    case tourist
    case unknown

    init(rawCategory: String) {
        self = Self(rawValue: rawCategory) ?? .unknown
    }

    var pinIconName: String {
        switch self {
        case .restaurant:
            "fork.knife"
        case .cafe:
            "cup.and.saucer"
        case .bar:
            "wineglass"
        case .museum, .park, .historic, .tourist:
            "leaf"
        case .unknown:
            "mappin"
        }
    }
}

struct MapPlace: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let category: ZanzarPlaceCategory
    let distanceMeters: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var pinIconName: String {
        category.pinIconName
    }
}

struct PlaceAPIResponse: Decodable, Sendable {
    let placeId: String
    let name: String
    let geometry: Geometry
    let zanzar: Zanzar
    let distanceMeters: Double

    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name
        case geometry
        case zanzar
        case distanceMeters
    }

    struct Geometry: Decodable, Sendable {
        let location: Location
    }

    struct Location: Decodable, Sendable {
        let lat: Double
        let lng: Double
    }

    struct Zanzar: Decodable, Sendable {
        let category: String
    }
}

extension MapPlace {
    init(response: PlaceAPIResponse) {
        id = response.placeId
        name = response.name
        latitude = response.geometry.location.lat
        longitude = response.geometry.location.lng
        category = ZanzarPlaceCategory(rawCategory: response.zanzar.category)
        distanceMeters = response.distanceMeters
    }
}
