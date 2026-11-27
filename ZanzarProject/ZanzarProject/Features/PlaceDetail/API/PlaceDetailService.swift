import Foundation

protocol PlaceDetailServicing: Sendable {
    func fetchPlaceDetail(context: PlaceDetailLoadContext) async throws -> PlaceDetail
    /// `mutationID` stays the same across retries of one check-in: the backend replays the full answer for an id
    /// it already accepted, instead of answering 409 and hiding the earned seal.
    /// `datetime` is when the user tapped, not when the request leaves: a check-in kept for later (no network) still
    /// says when it really happened.
    func checkIn(
        placeID: String,
        coordinate: UserCoordinate,
        mutationID: String,
        datetime: Date
    ) async throws -> CheckInResult
    /// Photos users sent of the place: approved ones, plus the signed-in user's own under review.
    func fetchUserPhotos(placeID: String) async throws -> [PlacePhoto]
}

extension PlaceDetailServicing {
    func fetchUserPhotos(placeID: String) async throws -> [PlacePhoto] { [] }

    func checkIn(placeID: String, coordinate: UserCoordinate, mutationID: String) async throws -> CheckInResult {
        try await checkIn(placeID: placeID, coordinate: coordinate, mutationID: mutationID, datetime: Date())
    }
}

nonisolated struct PlaceDetailAPIResponse: Decodable, Sendable {
    let placeId: String
    let name: String
    let nickname: String?
    let formattedAddress: String?
    let geometry: Geometry
    let editorialSummary: EditorialSummary?
    let openingHours: PlaceDetailOpeningHoursResponse?
    let photos: [PlacePhoto]
    let zanzar: PlaceDetailZanzarResponse
    let distanceMeters: Double?
    let userContext: PlaceUserContext?
    let accessibility: PlaceAccessibility?

    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name
        case nickname
        case formattedAddress = "formatted_address"
        case geometry
        case editorialSummary = "editorial_summary"
        case openingHours = "opening_hours"
        case images
        case zanzar
        case distanceMeters
        case userContext
        case accessibility
    }

    nonisolated struct Geometry: Decodable, Sendable {
        let location: Location
    }

    nonisolated struct Location: Decodable, Sendable {
        let lat: Double
        let lng: Double
    }

    nonisolated struct EditorialSummary: Decodable, Sendable {
        let overview: String
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        placeId = try container.decode(String.self, forKey: .placeId)
        name = try container.decode(String.self, forKey: .name)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        formattedAddress = try container.decodeIfPresent(String.self, forKey: .formattedAddress)
        geometry = try container.decode(Geometry.self, forKey: .geometry)
        editorialSummary = try container.decodeIfPresent(EditorialSummary.self, forKey: .editorialSummary)
        openingHours = try container.decodeIfPresent(PlaceDetailOpeningHoursResponse.self, forKey: .openingHours)
        photos = PlaceImageAPIResponse.photos(
            from: try container.decodeIfPresent([FailableDecodable<PlaceImageAPIResponse>].self, forKey: .images)
        )
        zanzar = try container.decode(PlaceDetailZanzarResponse.self, forKey: .zanzar)
        distanceMeters = try container.decodeIfPresent(Double.self, forKey: .distanceMeters)
        userContext = try container.decodeIfPresent(PlaceUserContext.self, forKey: .userContext)
        // A malformed `accessibility` hides the section instead of failing the whole place.
        accessibility = try container.decodeIfPresent(
            FailableDecodable<PlaceAccessibilityAPIResponse>.self,
            forKey: .accessibility
        )?.value?.accessibility
    }
}

nonisolated struct PlaceDetailOpeningHoursResponse: Decodable, Sendable {
    let openNow: Bool?
    /// The weekly periods, from which "open until 18h" is worked out. Malformed periods are not fatal here.
    let periods: [PlaceOpeningHoursAPIResponse.PeriodResponse]?

    enum CodingKeys: String, CodingKey {
        case openNow = "open_now"
        case periods
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        openNow = try container.decodeIfPresent(Bool.self, forKey: .openNow)
        periods = try? container.decodeIfPresent([PlaceOpeningHoursAPIResponse.PeriodResponse].self, forKey: .periods)
    }
}

nonisolated struct PlaceDetailZanzarResponse: Decodable, Sendable {
    let category: String
    let tags: [String]
    let checkInCount: Int
    let impressionCounts: [String: Int]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        category = try container.decode(String.self, forKey: .category)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        checkInCount = try container.decodeIfPresent(Int.self, forKey: .checkInCount) ?? 0
        impressionCounts = try container.decodeIfPresent([String: Int].self, forKey: .impressionCounts) ?? [:]
    }

    private enum CodingKeys: String, CodingKey {
        case category
        case tags
        case checkInCount
        case impressionCounts
    }
}

private struct CheckInCoordinates: Encodable, Sendable {
    let lat: Double
    let lng: Double
    let accuracyMeters: Double?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lat, forKey: .lat)
        try container.encode(lng, forKey: .lng)
        try container.encodeIfPresent(accuracyMeters, forKey: .accuracyMeters)
    }

    private enum CodingKeys: String, CodingKey {
        case lat
        case lng
        case accuracyMeters
    }
}

private struct CheckInCreateRequest: Encodable, Sendable {
    let placeId: String
    let datetime: String
    let clientMutationId: String
    let coordinates: CheckInCoordinates
}

private struct CheckInStatusResponse: Decodable, Sendable {
    let placeId: String
    /// When the check-in was made, as the backend stored it.
    let datetime: String?
}

/// Whether the signed-in user already checked in at a place, and when.
nonisolated struct CheckInStatus: Equatable, Sendable {
    let hasCheckedIn: Bool
    let checkedInAt: Date?

    static let notCheckedIn = CheckInStatus(hasCheckedIn: false, checkedInAt: nil)
}

private struct UserRatingResponse: Decodable, Sendable {
    let impressionTag: String
}

final class PlaceDetailService: PlaceDetailServicing {
    private let client: NetworkClient

    init(client: NetworkClient = URLSessionNetworkClient.shared) {
        self.client = client
    }

    func fetchPlaceDetail(context: PlaceDetailLoadContext) async throws -> PlaceDetail {
        AppLog.placeDetail.info("Fetching place detail placeId=\(context.place.id)...")
        do {
            let detail = try await loadPlaceDetail(context: context)
            AppLog.placeDetail.info("Fetched place detail placeId=\(context.place.id) successfully")
            return detail
        } catch {
            AppLog.placeDetail.error("Failed to fetch place detail placeId=\(context.place.id)", error: error)
            throw error
        }
    }

    func checkIn(
        placeID: String,
        coordinate: UserCoordinate,
        mutationID: String,
        datetime: Date
    ) async throws -> CheckInResult {
        AppLog.placeDetail.info("Checking in placeId=\(placeID)...")
        do {
            let result = try await sendCheckIn(
                placeID: placeID,
                coordinate: coordinate,
                mutationID: mutationID,
                datetime: datetime
            )
            AppLog.placeDetail.info("Checked in placeId=\(placeID) successfully (isNewStamp=\(result.isNewStamp))")
            return result
        } catch APIError.httpStatus(409, let message) {
            AppLog.placeDetail.warning("Check-in conflict (409) placeId=\(placeID)")
            throw APIError.httpStatus(409, message: message)
        } catch {
            AppLog.placeDetail.error("Failed to check in placeId=\(placeID)", error: error)
            throw error
        }
    }

    func fetchUserPhotos(placeID: String) async throws -> [PlacePhoto] {
        let response: PlaceUserPhotoListAPIResponse = try await client.get(path: "places/\(placeID)/photos")
        let photos = response.placePhotos
        AppLog.placeDetail.info("Fetched \(photos.count) user photos placeId=\(placeID)")
        return photos
    }

    private func loadPlaceDetail(context: PlaceDetailLoadContext) async throws -> PlaceDetail {
        let placeResponse: PlaceDetailAPIResponse = try await client.get(
            path: "places/\(context.place.id)"
        )

        async let checkInFromEndpoint = fetchCheckInStatus(
            placeID: context.place.id,
            userID: context.userID
        )
        async let selectedReactionTag = fetchSelectedReactionTag(
            placeID: context.place.id,
            userID: context.userID
        )

        let endpointStatus = try await checkInFromEndpoint
        let hasCheckedIn = placeResponse.userContext?.hasCheckedIn == true || endpointStatus.hasCheckedIn

        return PlaceDetail.make(
            placeResponse: placeResponse,
            mapPlace: context.place,
            hasCheckedIn: hasCheckedIn,
            checkedInAt: endpointStatus.checkedInAt,
            selectedReactionTag: try await selectedReactionTag,
            userCoordinate: context.userCoordinate
        )
    }

    private func sendCheckIn(
        placeID: String,
        coordinate: UserCoordinate,
        mutationID: String,
        datetime: Date
    ) async throws -> CheckInResult {
        let response: CheckInAPIResponse = try await client.send(
            path: "checkIn",
            method: .post,
            body: CheckInCreateRequest(
                placeId: placeID,
                datetime: datetime.formatted(.iso8601),
                clientMutationId: mutationID,
                coordinates: CheckInCoordinates(
                    lat: coordinate.latitude,
                    lng: coordinate.longitude,
                    accuracyMeters: coordinate.accuracyMeters
                )
            )
        )
        return response.makeCheckInResult()
    }

    private func fetchCheckInStatus(placeID: String, userID: String?) async throws -> CheckInStatus {
        guard userID != nil else { return .notCheckedIn }

        do {
            let response: CheckInStatusResponse = try await client.get(
                path: "checkIn",
                queryItems: [URLQueryItem(name: "placeId", value: placeID)]
            )
            return CheckInStatus(hasCheckedIn: true, checkedInAt: response.datetime.flatMap(APIDate.parse))
        } catch APIError.httpStatus(404, _) {
            return .notCheckedIn
        } catch APIError.httpStatus(401, _), APIError.httpStatus(403, _) {
            return .notCheckedIn
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            // A side call must not hide the place. A wrong "not checked in" is safe: check-in answers 409.
            AppLog.placeDetail.warning("Check-in status unavailable placeId=\(placeID)")
            return .notCheckedIn
        }
    }

    private func fetchSelectedReactionTag(placeID: String, userID: String?) async throws -> String? {
        guard userID != nil else { return nil }

        do {
            let response: UserRatingResponse = try await client.get(
                path: "rating",
                queryItems: [URLQueryItem(name: "placeId", value: placeID)]
            )
            return response.impressionTag
        } catch APIError.httpStatus(404, _) {
            return nil
        } catch APIError.httpStatus(401, _), APIError.httpStatus(403, _) {
            return nil
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            AppLog.placeDetail.warning("Reaction unavailable placeId=\(placeID)")
            return nil
        }
    }
}
