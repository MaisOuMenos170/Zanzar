import SwiftUI

struct ItineraryView: View {
    let slug: String?
    @State private var viewModel = ItineraryViewModel()
    @Environment(AppCoordinator.self) private var coordinator

    init(slug: String? = nil) {
        self.slug = slug
    }

    var body: some View {
        // TODO(E3-05): build the detail UI for `slug`.
        Text("itinerary.placeholder.title")
    }
}

#Preview {
    ItineraryView(slug: "centro-historico")
        .environment(AppCoordinator())
}
