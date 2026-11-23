import SwiftUI

/// "Lugares salvos" (Figma "Perfil", node 2678:2192): the places the user bookmarked, searchable and filterable,
/// each with a button to take it off the list.
struct SavedPlacesView: View {
    @State private var viewModel = SavedPlacesViewModel()
    @Environment(NearbyPlacesStore.self) private var nearbyPlacesStore
    @Environment(ToastManager.self) private var toasts
    /// The place whose trash button was tapped, while the alert asks whether to really take it off.
    @State private var placePendingRemoval: SavedPlace?

    /// What the map already knows about each place; the saved list itself has no category.
    private var categories: [String: ZanzarPlaceCategory] {
        Dictionary(nearbyPlacesStore.places.map { ($0.id, $0.category) }, uniquingKeysWith: { first, _ in first })
    }

    var body: some View {
        let known = categories
        let visible = viewModel.visiblePlaces { known[$0.placeID] }
        ListScreenScaffold(
            title: "savedPlaces.title",
            searchPrompt: "places.all.search.prompt",
            searchText: $viewModel.searchText,
            filter: $viewModel.filter,
            count: Text("places.all.count \(visible.count)")
        ) {
            content(visible: visible)
        }
        .alert(
            "savedPlaces.remove.confirmation.title",
            isPresented: Binding(
                get: { placePendingRemoval != nil },
                set: { if !$0 { placePendingRemoval = nil } }
            ),
            presenting: placePendingRemoval
        ) { place in
            Button("savedPlaces.remove.confirmation.confirmButton", role: .destructive) {
                Task { await remove(place) }
            }
            Button("savedPlaces.remove.confirmation.cancelButton", role: .cancel) {}
        } message: { place in
            Text("savedPlaces.remove.confirmation.message \(place.displayName)")
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        // Saved or removed on the place's own screen.
        .onReceive(NotificationCenter.default.publisher(for: AppNotification.savedPlacesDidChange)) { _ in
            Task { await viewModel.load() }
        }
    }

    @ViewBuilder
    private func content(visible: [SavedPlace]) -> some View {
        if let errorMessage = viewModel.errorMessage, viewModel.places.isEmpty {
            ContentUnavailableView {
                Label("profile.errorState.title", systemImage: "exclamationmark.triangle")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("profile.errorState.retryButton.title") {
                    Task { await viewModel.load() }
                }
            }
        } else if !viewModel.hasLoaded {
            ListLoadingView()
        } else if visible.isEmpty {
            ListNoResultsView(kind: emptyKind)
        } else {
            LazyVStack(spacing: 0) {
                ForEach(visible) { place in
                    if place.id != visible.first?.id {
                        Divider()
                            .overlay(Color.brandPurple100)
                    }
                    SavedPlaceRow(place: place) {
                        placePendingRemoval = place
                    }
                }
            }
            .background(Color.brandNeutral50, in: .rect(cornerRadius: 16))
            .clipShape(.rect(cornerRadius: 16))
        }
    }

    private var emptyKind: ListNoResultsView.Kind {
        if viewModel.places.isEmpty {
            return .empty(title: "savedPlaces.empty.title", message: "savedPlaces.empty.message")
        }
        let query = viewModel.trimmedQuery
        guard !query.isEmpty else { return .filtered }
        return .custom(title: "savedPlaces.noResults.title \(query)", message: "savedPlaces.noResults.message")
    }

    private func remove(_ place: SavedPlace) async {
        switch await viewModel.remove(place) {
        case .removed:
            toasts.show(L10n.string("placeDetail.saveButton.removedToast"), style: .positive, position: .bottom)
        case .failed(let message):
            toasts.show(message, style: .negative, position: .bottom)
        case nil:
            break
        }
    }
}

#Preview {
    NavigationStack {
        SavedPlacesView()
    }
    .environment(NearbyPlacesStore())
    .environment(ToastManager())
}
