import Foundation
import UIKit

protocol UserPhotosServicing: Sendable {
    func fetchTermsStatus(userID: String) async throws -> PhotoTermsStatus
    func acceptTerms(userID: String, birthDate: Date) async throws -> PhotoTermsStatus
    func upload(
        _ photo: PreparedPhoto,
        placeID: String,
        fromCheckIn: Bool,
        showsAuthorName: Bool
    ) async throws -> UserPhoto
    func fetchMyPhotos(userID: String) async throws -> [UserPhoto]
    func deletePhoto(_ photoID: String, placeID: String) async throws
    func reportPhoto(_ photoID: String, placeID: String, reason: PhotoReportReason, note: String?) async throws
    func blockAuthor(ofPhoto photoID: String, userID: String) async throws
    func fetchBlockedUsers(userID: String) async throws -> [BlockedUser]
    func unblock(_ blockedUserID: String, userID: String) async throws
}

final class UserPhotosService: UserPhotosServicing {
    private let client: NetworkClient

    init(client: NetworkClient = URLSessionNetworkClient.shared) {
        self.client = client
    }

    func fetchTermsStatus(userID: String) async throws -> PhotoTermsStatus {
        let response: PhotoTermsAPIResponse = try await client.get(path: "user/\(userID)/photo-terms")
        return response.status
    }

    func acceptTerms(userID: String, birthDate: Date) async throws -> PhotoTermsStatus {
        do {
            let response: PhotoTermsAPIResponse = try await client.send(
                path: "user/\(userID)/photo-terms",
                method: .post,
                body: AcceptPhotoTermsRequest(version: PhotoTerms.version, birthDate: Self.dayString(birthDate))
            )
            AppLog.userPhotos.info("Accepted photo terms version=\(PhotoTerms.version)")
            return response.status
        } catch APIError.rejected(_, "underage", _) {
            AppLog.userPhotos.info("Photo terms refused: under the minimum age")
            return PhotoTermsStatus(hasAcceptedCurrentTerms: false, isAdult: false)
        }
    }

    func upload(
        _ photo: PreparedPhoto,
        placeID: String,
        fromCheckIn: Bool,
        showsAuthorName: Bool
    ) async throws -> UserPhoto {
        AppLog.userPhotos.info(
            "Uploading photo placeId=\(placeID) bytes=\(photo.jpeg.count) fromCheckIn=\(fromCheckIn)"
        )
        // Lets a send that started in the foreground finish if the user leaves the app (about 30 s).
        let backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "UserPhotoUpload")
        defer { UIApplication.shared.endBackgroundTask(backgroundTask) }
        do {
            let response: UserPhotoAPIResponse = try await client.upload(
                path: "places/\(placeID)/photos",
                queryItems: [
                    URLQueryItem(name: "fromCheckIn", value: String(fromCheckIn)),
                    URLQueryItem(name: "showAuthorName", value: String(showsAuthorName))
                ],
                data: photo.jpeg,
                contentType: "image/jpeg"
            )
            AppLog.userPhotos.info("Uploaded photo placeId=\(placeID) status=\(response.status.rawValue)")
            return response.userPhoto
        } catch {
            let mapped = PhotoUploadError(error)
            AppLog.userPhotos.warning("Photo upload failed placeId=\(placeID) reason=\(String(describing: mapped))")
            throw mapped
        }
    }

    func fetchMyPhotos(userID: String) async throws -> [UserPhoto] {
        let response: UserPhotoListAPIResponse = try await client.get(path: "user/\(userID)/photos")
        return response.photos.compactMap { $0.value?.userPhoto }
    }

    func deletePhoto(_ photoID: String, placeID: String) async throws {
        try await client.sendWithoutResponse(path: "places/\(placeID)/photos/\(photoID)", method: .delete)
        AppLog.userPhotos.info("Deleted own photo photoId=\(photoID)")
    }

    func reportPhoto(_ photoID: String, placeID: String, reason: PhotoReportReason, note: String?) async throws {
        do {
            let _: AcceptedReportAPIResponse = try await client.send(
                path: "places/\(placeID)/photos/\(photoID)/reports",
                method: .post,
                body: ReportPhotoRequest(reason: reason.rawValue, note: note)
            )
        } catch APIError.rejected(409, "already_reported", _) {
            // Reporting twice is not an error for the user: the first report stands.
        }
        AppLog.userPhotos.info("Reported photo photoId=\(photoID) reason=\(reason.rawValue)")
    }

    func blockAuthor(ofPhoto photoID: String, userID: String) async throws {
        try await client.sendWithoutResponse(
            path: "user/\(userID)/blocks",
            method: .post,
            body: BlockUserRequest(photoId: photoID)
        )
        AppLog.userPhotos.info("Blocked the author of photoId=\(photoID)")
    }

    func fetchBlockedUsers(userID: String) async throws -> [BlockedUser] {
        let response: BlockedUsersAPIResponse = try await client.get(path: "user/\(userID)/blocks")
        return response.blockedUsers.compactMap { $0.value?.blockedUser }
    }

    func unblock(_ blockedUserID: String, userID: String) async throws {
        try await client.sendWithoutResponse(path: "user/\(userID)/blocks/\(blockedUserID)", method: .delete)
    }

    /// `YYYY-MM-DD` in the user's calendar day, which is what they picked.
    nonisolated static func dayString(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
