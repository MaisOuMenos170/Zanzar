import Foundation
@testable import ZanzarProject

final class FakePasswordResetService: PasswordResetServicing, @unchecked Sendable {
    var requestCodeError: Error?
    var verifyResult: Result<String, Error> = .success("reset-token")
    var resetError: Error?

    private(set) var requestedEmails: [String] = []
    private(set) var verifyRequests: [VerifyResetRequest] = []
    private(set) var resetCalls: [(resetToken: String, newPassword: String)] = []

    func requestCode(email: String) async throws {
        requestedEmails.append(email)
        if let requestCodeError { throw requestCodeError }
    }

    func verify(_ request: VerifyResetRequest) async throws -> String {
        verifyRequests.append(request)
        return try verifyResult.get()
    }

    func resetPassword(resetToken: String, newPassword: String) async throws {
        resetCalls.append((resetToken, newPassword))
        if let resetError { throw resetError }
    }
}
