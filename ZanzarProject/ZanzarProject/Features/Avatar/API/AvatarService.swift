import Foundation

protocol AvatarServicing: Sendable {
    /// Returns `nil` when the user has not created an avatar yet (the backend answers `404`).
    func fetchAvatar(userID: String) async throws -> Avatar?
    func createAvatar(userID: String, avatar: Avatar) async throws -> Avatar
    /// Replaces every layer of an existing avatar (`PATCH`; the backend answers `404` when there is none).
    func updateAvatar(userID: String, avatar: Avatar) async throws -> Avatar
}

struct AvatarAPIRequest: Encodable, Sendable {
    let skin: Int
    let eyes: Int
    let eyebrow: Int
    let eyelash: Int
    let hair: Int
    let background: String

    init(avatar: Avatar) {
        skin = avatar.skin
        eyes = avatar.eyes
        eyebrow = avatar.eyebrow
        eyelash = avatar.eyelash
        hair = avatar.hair
        background = avatar.background
    }
}

/// Wire format of `GET /user/:id/avatar`: ids of the local images of each layer (0 = none for `eyelash` and `hair`).
struct AvatarAPIResponse: Decodable, Sendable {
    let skin: Int
    let eyes: Int
    let eyebrow: Int
    /// Avatars saved before eyelashes existed come without the field; they were all drawn with the first eyelash.
    let eyelash: Int?
    let hair: Int
    let background: String

    func makeAvatar() -> Avatar {
        Avatar(
            skin: skin,
            eyes: eyes,
            eyebrow: eyebrow,
            eyelash: eyelash ?? 1,
            hair: hair,
            background: background
        )
    }
}

/// A `200` whose body is `null`, `{}` or otherwise has no avatar layers counts as "no avatar yet", like a `404`.
struct OptionalAvatarAPIResponse: Decodable, Sendable {
    let avatar: AvatarAPIResponse?

    init(from decoder: Decoder) throws {
        avatar = try? AvatarAPIResponse(from: decoder)
    }
}

final class AvatarService: AvatarServicing {
    private let client: NetworkClient

    init(client: NetworkClient = URLSessionNetworkClient.shared) {
        self.client = client
    }

    func fetchAvatar(userID: String) async throws -> Avatar? {
        // The id comes from the JWT and is interpolated into the path, so it must not add segments.
        guard Self.isSafePathSegment(userID) else {
            AppLog.avatar.error("Refusing to fetch an avatar for a malformed user id")
            throw APIError.invalidRequest
        }
        AppLog.avatar.info("Fetching avatar")
        do {
            let response: OptionalAvatarAPIResponse = try await client.get(path: "user/\(userID)/avatar")
            guard let avatar = response.avatar else {
                AppLog.avatar.info("The avatar response is empty")
                return nil
            }
            AppLog.avatar.info("Avatar fetched")
            return avatar.makeAvatar()
        } catch APIError.httpStatus(404, _) {
            AppLog.avatar.info("User has no avatar yet")
            return nil
        } catch {
            AppLog.avatar.error("Avatar request failed", error: error)
            throw error
        }
    }

    func createAvatar(userID: String, avatar: Avatar) async throws -> Avatar {
        guard Self.isSafePathSegment(userID) else {
            AppLog.avatar.error("Refusing to create an avatar for a malformed user id")
            throw APIError.invalidRequest
        }
        AppLog.avatar.info("Creating avatar")
        do {
            let response: AvatarAPIResponse = try await client.send(
                path: "user/\(userID)/avatar",
                method: .post,
                body: AvatarAPIRequest(avatar: avatar)
            )
            AppLog.avatar.info("Avatar created")
            return response.makeAvatar()
        } catch {
            AppLog.avatar.error("Create avatar request failed", error: error)
            throw error
        }
    }

    func updateAvatar(userID: String, avatar: Avatar) async throws -> Avatar {
        guard Self.isSafePathSegment(userID) else {
            AppLog.avatar.error("Refusing to update an avatar for a malformed user id")
            throw APIError.invalidRequest
        }
        AppLog.avatar.info("Updating avatar")
        do {
            let response: AvatarAPIResponse = try await client.send(
                path: "user/\(userID)/avatar",
                method: .patch,
                body: AvatarAPIRequest(avatar: avatar)
            )
            AppLog.avatar.info("Avatar updated")
            return response.makeAvatar()
        } catch {
            AppLog.avatar.error("Update avatar request failed", error: error)
            throw error
        }
    }

    private static func isSafePathSegment(_ value: String) -> Bool {
        !value.isEmpty && value.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") }
    }
}
