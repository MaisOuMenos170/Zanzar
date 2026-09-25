import Observation

@Observable
final class WelcomeViewModel {
    private let service: WelcomeServicing

    init(service: WelcomeServicing = WelcomeService()) {
        self.service = service
    }

    func createAccountTapped() {
        // TODO: navigate to sign-up flow when auth is implemented
    }

    func loginTapped() {
        // TODO: navigate to login flow when auth is implemented
    }
}
