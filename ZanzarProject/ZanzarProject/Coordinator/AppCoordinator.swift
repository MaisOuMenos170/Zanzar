import SwiftUI

@Observable
final class AppCoordinator {
    var path = NavigationPath()

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

    @ViewBuilder
    func view(for route: Route) -> some View {
        switch route {
        case .locationMark:
            LocationMarkView()
        }
    }
}
