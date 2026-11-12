import Foundation
@testable import ZanzarProject

/// Records calls and answers with configured results. Every unconfigured call fails, so tests notice it.
nonisolated final class MockUserPhotosService: UserPhotosServicing, @unchecked Sendable {
    static let adultWithTerms = PhotoTermsStatus(hasAcceptedCurrentTerms: true, isAdult: true)

    var termsStatus: Result<PhotoTermsStatus, Error> = .success(adultWithTerms)
    var acceptResult: Result<PhotoTermsStatus, Error> = .success(adultWithTerms)
    var uploadResult: Result<UserPhoto, Error> = .success(.fixture())
    var myPhotos: Result<[UserPhoto], Error> = .success([])
    var deleteError: Error?
    var reportError: Error?
    var blockError: Error?
    var blockedUsers: [BlockedUser] = []

    struct Upload {
        let photo: PreparedPhoto
        let placeID: String
        let fromCheckIn: Bool
        let showsAuthorName: Bool
    }

    struct Report {
        let photoID: String
        let reason: PhotoReportReason
        let note: String?
    }

    private(set) var uploads: [Upload] = []
    private(set) var acceptedBirthDates: [Date] = []
    private(set) var deletedPhotoIDs: [String] = []
    private(set) var reports: [Report] = []
    private(set) var blockedPhotoIDs: [String] = []
    private(set) var unblockedUserIDs: [String] = []

    func fetchTermsStatus(userID: String) async throws -> PhotoTermsStatus { try termsStatus.get() }

    func acceptTerms(userID: String, birthDate: Date) async throws -> PhotoTermsStatus {
        acceptedBirthDates.append(birthDate)
        return try acceptResult.get()
    }

    func upload(
        _ photo: PreparedPhoto,
        placeID: String,
        fromCheckIn: Bool,
        showsAuthorName: Bool
    ) async throws -> UserPhoto {
        let upload = Upload(photo: photo, placeID: placeID, fromCheckIn: fromCheckIn, showsAuthorName: showsAuthorName)
        uploads.append(upload)
        return try uploadResult.get()
    }

    func fetchMyPhotos(userID: String) async throws -> [UserPhoto] { try myPhotos.get() }

    func deletePhoto(_ photoID: String, placeID: String) async throws {
        if let deleteError { throw deleteError }
        deletedPhotoIDs.append(photoID)
    }

    func reportPhoto(
        _ photoID: String,
        placeID: String,
        reason: PhotoReportReason,
        note: String?
    ) async throws {
        if let reportError { throw reportError }
        reports.append(Report(photoID: photoID, reason: reason, note: note))
    }

    func blockAuthor(ofPhoto photoID: String, userID: String) async throws {
        if let blockError { throw blockError }
        blockedPhotoIDs.append(photoID)
    }

    func fetchBlockedUsers(userID: String) async throws -> [BlockedUser] { blockedUsers }

    func unblock(_ blockedUserID: String, userID: String) async throws {
        unblockedUserIDs.append(blockedUserID)
    }
}

nonisolated extension UserPhoto {
    static func fixture(
        id: String = "photo-1",
        status: UserPhotoStatus = .pending,
        reason: UserPhotoDecisionReason? = nil
    ) -> UserPhoto {
        UserPhoto(
            id: id,
            placeID: "place-1",
            placeName: "Bar do Teste",
            status: status,
            isVerifiedCheckIn: false,
            showsAuthorName: true,
            thumbnailURL: nil,
            imageURL: nil,
            decisionReason: reason,
            createdAt: Date(timeIntervalSince1970: 1_800_000_000),
            decidedAt: nil
        )
    }
}
