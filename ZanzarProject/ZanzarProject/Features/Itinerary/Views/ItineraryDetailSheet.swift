import SwiftUI

struct ItineraryDetailSheet: View {
    let slug: String
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        NavigationStack {
            ItineraryView(slug: slug)
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
