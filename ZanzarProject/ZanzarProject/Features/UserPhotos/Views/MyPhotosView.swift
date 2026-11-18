import SwiftUI

/// All the photos the user sent and where each one stands. Reached from the profile.
struct MyPhotosView: View {
    @State private var viewModel = MyPhotosViewModel()
    @State private var searchText = ""

    private var visiblePhotos: [UserPhoto] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return viewModel.photos }
        return viewModel.photos.filter { $0.placeName?.localizedStandardContains(query) == true }
    }

    var body: some View {
        ListScreenScaffold(
            title: "userPhotos.myPhotos.screenTitle",
            searchPrompt: "userPhotos.myPhotos.search.prompt",
            searchText: $searchText,
            count: Text("userPhotos.myPhotos.count \(visiblePhotos.count)")
        ) {
            content
        }
        .motion(Motion.suave, value: [viewModel.hasLoaded, viewModel.photos.isEmpty])
        .motion(Motion.assentar, value: viewModel.photos.map(\.id))
        .haptic(.alerta, trigger: viewModel.photoPendingDeletion?.id, when: { _, photoID in photoID != nil })
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.photos.isEmpty && !viewModel.hasLoaded {
            ListLoadingView()
        } else if visiblePhotos.isEmpty {
            ListNoResultsView(
                hasItems: !viewModel.photos.isEmpty,
                query: searchText,
                emptyTitle: "userPhotos.myPhotos.empty.title",
                emptyMessage: "userPhotos.myPhotos.empty.message",
                notFoundMessage: "list.noResults.place.message"
            )
        } else {
            UserPhotoListCard(photos: visiblePhotos, viewModel: viewModel)
        }
    }
}
