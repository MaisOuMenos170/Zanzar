import SwiftUI

struct ItineraryDetailSheet: View {
    let slug: String
    let onSelectPlace: (MapPlace) -> Void
    @State private var viewModel: ItineraryDetailViewModel

    init(slug: String, onSelectPlace: @escaping (MapPlace) -> Void) {
        self.slug = slug
        self.onSelectPlace = onSelectPlace
        _viewModel = State(initialValue: ItineraryDetailViewModel(slug: slug))
    }

    var body: some View {
        NavigationStack {
            ItineraryDetailView(
                viewModel: viewModel,
                onItineraryChanged: {
                    // The list tab reloads active progress when this sheet dismisses via notification,
                    // but we also call the callback for any immediate UI updates the presenter may need.
                },
                onSelectPlace: onSelectPlace
            )
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    ItineraryDetailSheet(slug: "centro-historico", onSelectPlace: { _ in })
        .environment(AppCoordinator())
        .environment(NearbyPlacesStore())
}
