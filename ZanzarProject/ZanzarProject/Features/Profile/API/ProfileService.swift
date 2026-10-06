import Foundation

protocol ProfileServicing: Sendable {
    func fetchProfile(userID: String, limit: Int) async throws -> Profile
    func logout() async throws
}

struct ProfileAPIResponse: Decodable, Sendable {
    let username: String
    let checkInCount: Int
    let completedItinerariesCount: Int
    let stampsCount: Int
    let recentCheckIns: [RecentCheckInAPIResponse]

    func makeProfile() throws -> Profile {
        Profile(
            summary: ProfileSummary(
                name: username,
                checkInCount: checkInCount,
                itineraryCount: completedItinerariesCount,
                sealCount: stampsCount
            ),
            recentCheckIns: makeCheckIns()
        )
    }

    /// One malformed entry is dropped (and logged) instead of failing the whole profile.
    private func makeCheckIns() -> [ProfileCheckIn] {
        var seenIDs: [String: Int] = [:]
        return recentCheckIns.compactMap { response in
            guard var checkIn = try? response.makeCheckIn() else {
                AppLog.profile.warning("Skipping a check-in with an unparseable datetime")
                return nil
            }
            // The id is derived from place + moment; keep it unique if the backend repeats an entry.
            let occurrence = seenIDs[checkIn.id, default: 0]
            seenIDs[checkIn.id] = occurrence + 1
            if occurrence > 0 {
                checkIn = checkIn.withID("\(checkIn.id)#\(occurrence)")
            }
            return checkIn
        }
    }
}

struct RecentCheckInAPIResponse: Decodable, Sendable {
    let placeId: String
    let placeName: String?
    let datetime: String
    let photoReference: String?
    let stamp: StampAPIResponse?

    struct StampAPIResponse: Decodable, Sendable {
        let stampId: String
        let imageUrl: String
    }

    func makeCheckIn() throws -> ProfileCheckIn {
        ProfileCheckIn(
            id: "\(placeId)|\(datetime)",
            placeID: placeId,
            placeName: placeName,
            date: try Self.parseDate(datetime),
            photoReference: photoReference,
            sealCategory: stamp.flatMap { Self.sealCategory(forStampID: $0.stampId) }
        )
    }

    /// The backend names stamps `stamp_<category>` (e.g. `stamp_bar`); the app's seals are keyed by category.
    /// An unrecognised stamp yields `nil` because `.unknown` would render the restaurant seal.
    private static func sealCategory(forStampID stampID: String) -> ZanzarPlaceCategory? {
        let name = stampID.hasPrefix("stamp_") ? String(stampID.dropFirst("stamp_".count)) : stampID
        let category = ZanzarPlaceCategory(rawCategory: name)
        return category == .unknown ? nil : category
    }

    private static func parseDate(_ value: String) throws -> Date {
        if let date = try? Date(value, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true)) {
            return date
        }
        if let date = try? Date(value, strategy: Date.ISO8601FormatStyle()) {
            return date
        }
        throw APIError.decodingFailed
    }
}

final class ProfileService: ProfileServicing {
    private let client: NetworkClient

    init(client: NetworkClient = URLSessionNetworkClient.shared) {
        self.client = client
    }

    func fetchProfile(userID: String, limit: Int) async throws -> Profile {
        // The id comes from the JWT and is interpolated into the path, so it must not add segments.
        guard Self.isSafePathSegment(userID) else {
            AppLog.profile.error("Refusing to fetch a profile for a malformed user id")
            throw APIError.invalidRequest
        }
        AppLog.profile.info("Fetching profile (limit=\(limit))")
        do {
            let response: ProfileAPIResponse = try await client.get(
                path: "user/\(userID)/profile",
                queryItems: [URLQueryItem(name: "limit", value: String(limit))]
            )
            let profile = try response.makeProfile()
            AppLog.profile.info("Profile fetched (recentCheckIns=\(profile.recentCheckIns.count))")
            return profile
        } catch {
            AppLog.profile.error("Profile request failed", error: error)
            throw error
        }
    }

    private static func isSafePathSegment(_ value: String) -> Bool {
        !value.isEmpty && value.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") }
    }

    func logout() async throws {
        AppLog.profile.info("Requesting server logout")
        do {
            try await client.sendWithoutResponse(path: "logout", method: .post)
            AppLog.profile.info("Server logout succeeded")
        } catch {
            AppLog.profile.error("Server logout failed", error: error)
            throw error
        }
    }
}
