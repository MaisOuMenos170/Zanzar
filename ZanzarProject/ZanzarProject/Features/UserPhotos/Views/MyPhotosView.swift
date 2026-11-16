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
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.photos.isEmpty && viewModel.hasLoaded {
            ContentUnavailableView(
                "userPhotos.myPhotos.empty.title",
                systemImage: "photo.on.rectangle.angled",
                description: Text("userPhotos.myPhotos.empty.message")
            )
        } else if viewModel.photos.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
        } else if visiblePhotos.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            UserPhotoListCard(photos: visiblePhotos, viewModel: viewModel)
        }
    }
}
