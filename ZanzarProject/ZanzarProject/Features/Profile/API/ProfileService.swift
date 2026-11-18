import Foundation

protocol ProfileServicing: Sendable {
    func fetchProfile(userID: String, limit: Int) async throws -> Profile
    func logout() async throws
    /// One page of the user's check-ins, newest first. `before` is the `nextCursor` of the previous page.
    func fetchCheckIns(userID: String, limit: Int, before: String?) async throws -> ProfileCheckInsPage
    /// Changes the name shown on the profile.
    func updateName(userID: String, name: String) async throws
    /// Deletes the account and everything that belongs to it.
    func deleteAccount(userID: String) async throws
}

extension ProfileServicing {
    func fetchCheckIns(userID: String, limit: Int, before: String?) async throws -> ProfileCheckInsPage {
        throw APIError.invalidRequest
    }

    // Defaults so test doubles that never edit the account don't have to implement these.
    func updateName(userID: String, name: String) async throws {
        throw APIError.invalidRequest
    }

    func deleteAccount(userID: String) async throws {
        throw APIError.invalidRequest
    }
}

/// `GET user/{id}/check-ins`: a page of check-ins and where the next page starts.
struct CheckInsPageAPIResponse: Decodable, Sendable {
    let checkIns: [RecentCheckInAPIResponse]
    /// Sent back as `before` to ask for the next page; `nil` on the last one.
    let nextCursor: String?

    func makePage() -> ProfileCheckInsPage {
        // One malformed entry is dropped (and logged) instead of failing the whole page.
        let items = checkIns.compactMap { response -> ProfileCheckIn? in
            guard let checkIn = try? response.makeCheckIn() else {
                AppLog.profile.warning("Skipping a check-in with an unparseable datetime")
                return nil
            }
            return checkIn
        }
        return ProfileCheckInsPage(checkIns: items, nextCursor: nextCursor)
    }
}

/// Body of `PATCH user/{id}`.
nonisolated struct UpdateNameRequest: Encodable, Sendable {
    let username: String
}

struct ProfileAPIResponse: Decodable, Sendable {
    let username: String
    let checkInCount: Int
    let itinerariesCount: Int
    let stampsCount: Int
    let recentCheckIns: [RecentCheckInAPIResponse]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        username = try container.decode(String.self, forKey: .username)
        checkInCount = try container.decode(Int.self, forKey: .checkInCount)
        stampsCount = try container.decode(Int.self, forKey: .stampsCount)
        recentCheckIns = try container.decode([RecentCheckInAPIResponse].self, forKey: .recentCheckIns)
        if let itinerariesCount = try container.decodeIfPresent(Int.self, forKey: .itinerariesCount) {
            self.itinerariesCount = itinerariesCount
        } else if let legacyCount = try container.decodeIfPresent(Int.self, forKey: .completedItinerariesCount) {
            // Servers that have not picked up the profile rename still send only completed itineraries.
            itinerariesCount = legacyCount
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.itinerariesCount,
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Expected itinerariesCount or completedItinerariesCount"
                )
            )
        }
    }

    private enum CodingKeys: String, CodingKey {
        case username
        case checkInCount
        case itinerariesCount
        case completedItinerariesCount
        case stampsCount
        case recentCheckIns
    }

    func makeProfile() throws -> Profile {
        Profile(
            summary: ProfileSummary(
                name: username,
                checkInCount: checkInCount,
                itineraryCount: itinerariesCount,
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
    let imageUrl: String?
    let stamp: StampAPIResponse?
    let impressionTag: String?

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
            photoURL: imageUrl.flatMap(PlaceImageAPIResponse.httpsURL),
            sealCategory: stamp.flatMap { Self.sealCategory(forStampID: $0.stampId) },
            impressionTag: impressionTag.flatMap(ImpressionTag.init(rawValue:))
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

    func fetchCheckIns(userID: String, limit: Int, before: String?) async throws -> ProfileCheckInsPage {
        guard Self.isSafePathSegment(userID) else {
            AppLog.profile.error("Refusing to fetch check-ins for a malformed user id")
            throw APIError.invalidRequest
        }
        var queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        if let before {
            queryItems.append(URLQueryItem(name: "before", value: before))
        }
        do {
            let response: CheckInsPageAPIResponse = try await client.get(
                path: "user/\(userID)/check-ins",
                queryItems: queryItems
            )
            let page = response.makePage()
            AppLog.profile.info("Check-ins page fetched (count=\(page.checkIns.count), hasMore=\(page.nextCursor != nil))")
            return page
        } catch {
            AppLog.profile.error("Check-ins request failed", error: error)
            throw error
        }
    }

    func updateName(userID: String, name: String) async throws {
        guard Self.isSafePathSegment(userID) else {
            AppLog.profile.error("Refusing to rename a malformed user id")
            throw APIError.invalidRequest
        }
        AppLog.profile.info("Updating the profile name")
        do {
            try await client.sendWithoutResponse(
                path: "user/\(userID)",
                method: .patch,
                body: UpdateNameRequest(username: name)
            )
        } catch {
            AppLog.profile.error("Profile name update failed", error: error)
            throw error
        }
    }

    func deleteAccount(userID: String) async throws {
        guard Self.isSafePathSegment(userID) else {
            AppLog.profile.error("Refusing to delete a malformed user id")
            throw APIError.invalidRequest
        }
        AppLog.profile.info("Requesting account deletion")
        do {
            try await client.sendWithoutResponse(path: "user/\(userID)", method: .delete)
            AppLog.profile.info("Account deleted")
        } catch {
            AppLog.profile.error("Account deletion failed", error: error)
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
