import CoreLocation
import Foundation

/// The user's current position on the map — the domain shape the View/ViewModel work with,
/// distinct from CoreLocation's `CLLocation` (which the Service layer deals with).
struct UserCoordinate: Hashable, Sendable {
    let latitude: Double
    let longitude: Double
    var accuracyMeters: Double? = nil

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
    /// `nil` when the place was reached without a known user position (e.g. from the profile).
    let distanceMeters: Double?
    let pinStyle: LocationPinStyle
    /// Total check-ins at the place. The list endpoint includes this; callers that only have a pin default to 0.
    let checkInCount: Int
    let photoReference: String?
    let impressionCounts: [String: Int]

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
        distanceMeters: Double?,
        pinStyle: LocationPinStyle = .available,
        checkInCount: Int = 0,
        photoReference: String? = nil,
        impressionCounts: [String: Int] = [:]
    ) {
        self.id = id
        self.name = name
        self.nickname = nickname
        self.latitude = latitude
        self.longitude = longitude
        self.category = category
        self.distanceMeters = distanceMeters
        self.pinStyle = pinStyle
        self.checkInCount = checkInCount
        self.photoReference = photoReference
        self.impressionCounts = impressionCounts
    }
}

struct NearbyPlacePhoto: Decodable, Sendable {
    let photoReference: String

    enum CodingKeys: String, CodingKey {
        case photoReference = "photo_reference"
    }
}

struct NearbyPlaceZanzar: Decodable, Sendable {
    let category: String
    let checkInCount: Int
    let impressionCounts: [String: Int]

    private enum CodingKeys: String, CodingKey {
        case category
        case checkInCount
        case impressionCounts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        category = try container.decode(String.self, forKey: .category)
        checkInCount = try container.decodeIfPresent(Int.self, forKey: .checkInCount) ?? 0
        impressionCounts = try container.decodeIfPresent([String: Int].self, forKey: .impressionCounts) ?? [:]
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
    let photos: [NearbyPlacePhoto]
    let zanzar: NearbyPlaceZanzar
    let distanceMeters: Double
    let userContext: PlaceUserContext?

    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name
        case nickname
        case geometry
        case photos
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        placeId = try container.decode(String.self, forKey: .placeId)
        name = try container.decode(String.self, forKey: .name)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        geometry = try container.decode(Geometry.self, forKey: .geometry)
        photos = try container.decodeIfPresent([NearbyPlacePhoto].self, forKey: .photos) ?? []
        zanzar = try container.decode(NearbyPlaceZanzar.self, forKey: .zanzar)
        distanceMeters = try container.decode(Double.self, forKey: .distanceMeters)
        userContext = try container.decodeIfPresent(PlaceUserContext.self, forKey: .userContext)
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
        checkInCount = response.zanzar.checkInCount
        photoReference = response.photos.first?.photoReference
        impressionCounts = response.zanzar.impressionCounts
    }

    static func pinStyle(from context: PlaceUserContext?) -> LocationPinStyle {
        guard let context else { return .available }
        if context.hasCheckedIn { return .checkedIn }
        if context.isInActiveItinerary { return .inCurrentItinerary }
        return .available
    }
}
