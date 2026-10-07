import SwiftUI

struct ItineraryDetailSheet: View {
    let slug: String
    @Environment(AppCoordinator.self) private var coordinator
    @State private var viewModel: ItineraryDetailViewModel

    init(slug: String) {
        self.slug = slug
        _viewModel = State(initialValue: ItineraryDetailViewModel(slug: slug))
    }

    var body: some View {
        NavigationStack {
            ItineraryDetailView(viewModel: viewModel) {
                // The list tab reloads active progress when this sheet dismisses.
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("itinerary.detail.close", action: coordinator.dismissSheet)
                }
            }
        }
    }
}

#Preview {
    ItineraryDetailSheet(slug: "centro-historico")
        .environment(AppCoordinator())
}
