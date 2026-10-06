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
            recentCheckIns: try recentCheckIns.map { try $0.makeCheckIn() }
        )
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
            placeName: placeName,
            date: try Self.parseDate(datetime),
            photoReference: photoReference,
            sealCategory: stamp.map { ZanzarPlaceCategory(rawCategory: Self.categoryName(forStampID: $0.stampId)) }
        )
    }

    /// The backend names stamps `stamp_<category>` (e.g. `stamp_bar`); the app's seals are keyed by category.
    private static func categoryName(forStampID stampID: String) -> String {
        stampID.hasPrefix("stamp_") ? String(stampID.dropFirst("stamp_".count)) : stampID
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
