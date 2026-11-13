import SwiftUI

/// The card under the search bar with what the backend found, nearest first.
struct DiscoverSearchResultsPanel: View {
    let phase: DiscoverSearchViewModel.Phase
    let results: [MapPlace]
    let onSelect: (MapPlace) -> Void

    @ScaledMetric(relativeTo: .body) private var maxHeight: CGFloat = 360
    @State private var listHeight: CGFloat = 0

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .background(Color.brandNeutral50, in: .rect(cornerRadius: 24))
            .shadow(color: .black.opacity(0.25), radius: 4, y: 1)
            // The card grows and shrinks to its rows instead of jumping when the results arrive.
            .motion(Motion.assentar, value: listHeight)
            .motion(Motion.suave, value: phase)
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .idle:
            EmptyView()
        case .searching where results.isEmpty:
            HStack(spacing: 10) {
                ProgressView()
                Text("discover.search.searching")
                    .font(.subheadline)
                    .foregroundStyle(Color.brandNeutral600)
            }
            .padding(16)
        case .failed:
            message("discover.search.error")
        case .results where results.isEmpty:
            message("discover.search.empty")
        default:
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(results) { place in
                        DiscoverSearchResultRow(place: place) { onSelect(place) }
                        if place.id != results.last?.id {
                            Divider().padding(.leading, 66)
                        }
                    }
                }
                .padding(.vertical, 6)
                // A scroll view takes all the height it is offered; measuring the rows makes the card only as
                // tall as its content, up to `maxHeight`.
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { listHeight = $0 }
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(height: min(listHeight, maxHeight))
        }
    }

    private func message(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.subheadline)
            .foregroundStyle(Color.brandNeutral600)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(16)
    }
}

#Preview {
    DiscoverSearchResultsPanel(
        phase: .results,
        results: [
            MapPlace(
                id: "1", name: "Jardim Botânico", latitude: 0, longitude: 0, category: .park, distanceMeters: 1300
            ),
            MapPlace(
                id: "2", name: "Café do Mercado", latitude: 0, longitude: 0, category: .cafe, distanceMeters: 240
            )
        ],
        onSelect: { _ in }
    )
    .padding()
    .background(Color.gray.opacity(0.3))
}
