import Foundation
import Observation

/// Turns the email link into a reset token as soon as the sheet opens.
@Observable
final class PasswordResetLinkViewModel {
    enum State: Equatable {
        case verifying
        case ready(resetToken: String)
        case failed(message: String)
    }

    private let link: PasswordResetLink
    private let service: PasswordResetServicing
    /// The link token is single use, so a second `.task` run must not send it again.
    @ObservationIgnored private var hasStarted = false

    private(set) var state: State = .verifying

    init(link: PasswordResetLink, service: PasswordResetServicing = PasswordResetService()) {
        self.link = link
        self.service = service
    }

    func verify() async {
        guard !hasStarted else { return }
        hasStarted = true

        do {
            let resetToken = try await service.verify(.link(token: link.token))
            state = .ready(resetToken: resetToken)
        } catch let error as APIError {
            state = .failed(message: AuthErrorMapper.resetLinkMessage(for: error))
        } catch {
            // The sheet was closed mid-request: nobody is looking at the state any more.
            if error is CancellationError || (error as? URLError)?.code == .cancelled {
                return
            }
            state = .failed(message: L10n.string("passwordReset.link.error.generic"))
        }
    }
}
