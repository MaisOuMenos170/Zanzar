import SwiftUI

struct ItineraryDetailSheet: View {
    let slug: String
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
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    ItineraryDetailSheet(slug: "centro-historico")
        .environment(AppCoordinator())
}
