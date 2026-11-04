import SwiftUI

@Observable
final class AppCoordinator {
    var path = NavigationPath()
    var presentedSheet: Sheet?

    func finishAuthFlow() {
        popToRoot()
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
        case .signUp:
            SignUpView()
        case .login:
            LoginView()
        case .placeDetail(let place):
            PlaceDetailView(place: place)
        case .avatar:
            AvatarView()
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
