import SwiftUI

@Observable
final class AppCoordinator {
    var path = NavigationPath()
    var presentedSheet: Sheet?

    func finishAuthFlow() {
        popToRoot()
    }

    func startOnboarding() {
        popToRoot()
        push(.avatarEditor)
    }

    /// After a new password is saved: back to the login screen, so the user signs in with it.
    func returnToLogin() {
        popToRoot()
        push(.login)
    }

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeLast(path.count)
    }

    func present(sheet: Sheet) {
        presentedSheet = sheet
    }

    func dismissSheet() {
        presentedSheet = nil
    }

    @ViewBuilder
    func view(for route: Route) -> some View {
        switch route {
        case .signUp, .login, .forgotPassword, .resetCode, .newPassword:
            authView(for: route)
        case .placeDetail(let place):
            PlaceDetailView(place: place)
        case .avatar:
            AvatarView()
        case .avatarEditor:
            AvatarEditorView()
        case .passportIntro(let avatar, let username):
            PassportIntroView(avatar: avatar, username: username)
        case .notificationPermission:
            NotificationPermissionView()
        case .myPhotos:
            MyPhotosView()
        case .mySuggestions:
            MySuggestionsView()
        case .photoPrivacy:
            PhotoPrivacyView()
        }
    }

    /// Screens of the signed-out stack: sign up, login and password reset.
    @ViewBuilder
    private func authView(for route: Route) -> some View {
        switch route {
        case .signUp:
            SignUpView()
        case .forgotPassword:
            ForgotPasswordView()
        case .resetCode(let email):
            ResetCodeView(email: email)
        case .newPassword(let resetToken):
            NewPasswordView(resetToken: resetToken) { [weak self] in
                self?.returnToLogin()
            }
        case .login:
            LoginView()
        default:
            // Only the routes listed in `view(for:)` reach here.
            EmptyView()
        }
    }

    @ViewBuilder
    func view(
        for sheet: Sheet,
        onSelectPlace: @escaping (MapPlace) -> Void,
        onPlaceSuggestionFinished: @escaping (PlaceSuggestionOutcome) -> Void
    ) -> some View {
        switch sheet {
        case .itineraryDetail(let slug):
            ItineraryDetailSheet(slug: slug, onSelectPlace: onSelectPlace)
        case .suggestPlace:
            PlaceSuggestionSheetView(onFinished: onPlaceSuggestionFinished)
        }
    }
}
