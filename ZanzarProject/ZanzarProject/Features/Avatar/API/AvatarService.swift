import Foundation

protocol AvatarServicing: Sendable {
    /// Returns `nil` when the user has not created an avatar yet (the backend answers `404`).
    func fetchAvatar(userID: String) async throws -> Avatar?
    func createAvatar(userID: String, avatar: Avatar) async throws -> Avatar
}

struct AvatarAPIRequest: Encodable, Sendable {
    let skin: Int
    let eyes: Int
    let eyebrow: Int
    let hair: Int

    init(avatar: Avatar) {
        skin = avatar.skin
        eyes = avatar.eyes
        eyebrow = avatar.eyebrow
        hair = avatar.hair
    }
}

/// Wire format of `GET /user/:id/avatar`: 1-based ids of the local images of each layer.
struct AvatarAPIResponse: Decodable, Sendable {
    let skin: Int
    let eyes: Int
    let eyebrow: Int
    let hair: Int

    func makeAvatar() -> Avatar {
        Avatar(skin: skin, eyes: eyes, eyebrow: eyebrow, hair: hair)
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
            let response: AvatarAPIResponse = try await client.get(path: "user/\(userID)/avatar")
            AppLog.avatar.info("Avatar fetched")
            return response.makeAvatar()
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

    private static func isSafePathSegment(_ value: String) -> Bool {
        !value.isEmpty && value.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") }
    }
}
