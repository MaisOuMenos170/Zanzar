import Foundation
import Observation
import UserNotifications

/// Manages the APNs device token: keeps it in UserDefaults and sends it to the backend
/// once the user is authenticated. The backend uses it to send re-engagement pushes
/// (inactivity nudges, unfinished itineraries, streaks).
@MainActor
final class PushTokenManager: NSObject {
    static let shared = PushTokenManager()

    private let client = URLSessionNetworkClient.shared
    private let defaults = UserDefaults.standard
    private let deviceTokenKey = "zanzar.pushDeviceToken"
    private let sentKey = "zanzar.pushTokenSent"

    /// The token currently stored locally (nil if none).
    var storedToken: String? {
        defaults.string(forKey: deviceTokenKey)
    }

    /// Called by AppDelegate when APNs assigns a device token. Stores it locally and,
    /// if the user is already authenticated, sends it to the backend.
    func register(deviceToken: Data) async {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        guard tokenString != storedToken else { return }

        defaults.set(tokenString, forKey: deviceTokenKey)
        defaults.removeObject(forKey: sentKey) // force re-send to the backend

        AppLog.network.info("APNs device token received (\(tokenString.count) hex chars)")

        if AuthTokenStore.shared.getToken() != nil {
            await sendToBackend(token: tokenString)
        }
    }

    /// Sends the token to the backend. Call this after sign-in succeeds if we already
    /// have a stored token but haven't sent it yet.
    func sendIfNeeded() async {
        guard let token = storedToken,
              defaults.bool(forKey: sentKey) == false else { return }
        await sendToBackend(token: token)
    }

    private func sendToBackend(token: String) async {
        guard let userID = AuthTokenStore.shared.userID, Self.isSafePathSegment(userID) else {
            AppLog.network.warning("Skipping device token registration: no valid signed-in user")
            return
        }
        do {
            try await client.sendWithoutResponse(
                path: "user/\(userID)/device-token",
                method: .post,
                body: RegisterDeviceTokenBody(deviceToken: token)
            )
            defaults.set(true, forKey: sentKey)
            AppLog.network.info("Device token registered with backend")
        } catch {
            AppLog.network.warning("Failed to register device token with backend")
        }
    }

    private static func isSafePathSegment(_ value: String) -> Bool {
        !value.isEmpty && value.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") }
    }

    struct RegisterDeviceTokenBody: Encodable {
        let deviceToken: String
    }
}
