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
    case restaurant
    case bar
    case cafe
    case museum
    case park
    case tourist
    case historic
    case curiosity
    case party
    case unknown

    init(rawCategory: String) {
        self = Self(rawValue: rawCategory) ?? .unknown
    }

    /// SF Symbol aligned with Figma node 860:4084 (pins e selos).
    var pinIconName: String {
        switch self {
        case .restaurant:
            "fork.knife"
        case .bar:
            "wineglass"
        case .cafe:
            "cup.and.heat.waves.fill"
        case .museum:
            "building.columns.fill"
        case .park:
            "leaf"
        case .tourist:
            "signpost.right.and.left"
        case .historic:
            "scroll"
        case .curiosity:
            "eyes.inverse"
        case .party:
            "party.popper"
        case .unknown:
            "mappin"
        }
    }

    /// Raster seal from Figma node 860:4084 (Group 633180–633188).
    var sealImageName: String {
        switch self {
        case .restaurant:
            "PlaceCategorySealRestaurant"
        case .bar:
            "PlaceCategorySealBar"
        case .cafe:
            "PlaceCategorySealCafe"
        case .museum:
            "PlaceCategorySealMuseum"
        case .park:
            "PlaceCategorySealPark"
        case .tourist:
            "PlaceCategorySealTourist"
        case .historic:
            "PlaceCategorySealHistoric"
        case .curiosity:
            "PlaceCategorySealCuriosity"
        case .party:
            "PlaceCategorySealParty"
        case .unknown:
            "PlaceCategorySealRestaurant"
        }
    }
}

struct MapPlace: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let nickname: String?
    let latitude: Double
    let longitude: Double
    let category: ZanzarPlaceCategory
    let distanceMeters: Double
    let pinStyle: LocationPinStyle

    var displayName: String {
        PlaceDisplayNameResolver.displayName(nickname: nickname, name: name)
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var pinIconName: String {
        category.pinIconName
    }

    init(
        id: String,
        name: String,
        nickname: String? = nil,
        latitude: Double,
        longitude: Double,
        category: ZanzarPlaceCategory,
        distanceMeters: Double,
        pinStyle: LocationPinStyle = .available
    ) {
        self.id = id
        self.name = name
        self.nickname = nickname
        self.latitude = latitude
        self.longitude = longitude
        self.category = category
        self.distanceMeters = distanceMeters
        self.pinStyle = pinStyle
    }
}

struct PlaceUserContext: Decodable, Sendable {
    let hasCheckedIn: Bool
    let isInActiveItinerary: Bool
}

struct PlaceAPIResponse: Decodable, Sendable {
    let placeId: String
    let name: String
    let nickname: String?
    let geometry: Geometry
    let zanzar: Zanzar
    let distanceMeters: Double
    let userContext: PlaceUserContext?

    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name
        case nickname
        case geometry
        case zanzar
        case distanceMeters
        case userContext
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
        nickname = response.nickname
        latitude = response.geometry.location.lat
        longitude = response.geometry.location.lng
        category = ZanzarPlaceCategory(rawCategory: response.zanzar.category)
        distanceMeters = response.distanceMeters
        pinStyle = Self.pinStyle(from: response.userContext)
    }

    static func pinStyle(from context: PlaceUserContext?) -> LocationPinStyle {
        guard let context else { return .available }
        if context.hasCheckedIn { return .checkedIn }
        if context.isInActiveItinerary { return .inCurrentItinerary }
        return .available
    }
}
