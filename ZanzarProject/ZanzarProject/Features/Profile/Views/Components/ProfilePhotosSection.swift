import SwiftUI
import TipKit

/// "Minhas fotos": the latest photos the user sent, with a link to all of them.
struct ProfilePhotosSection: View {
    let onSeeMore: () -> Void

    @State private var viewModel = MyPhotosViewModel()
    @Environment(AppCoordinator.self) private var coordinator

    private let myPhotosTip = ProfileMyPhotosTip()
    private let previewCount = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ProfileSectionHeader(title: "profile.photosSection.myPhotos.title", onSeeMore: onSeeMore)
                .popoverTip(myPhotosTip, arrowEdge: .bottom)

            if viewModel.photos.isEmpty {
                Text(viewModel.hasLoaded ? "userPhotos.myPhotos.empty.title" : "profile.loadingIndicator.title")
                    .typography(.body2)
                    .foregroundStyle(Color.brandNeutral600)
            } else {
                UserPhotoListCard(photos: Array(viewModel.photos.prefix(previewCount)), viewModel: viewModel)
            }
        }
        // Reloads when "all photos" is popped: photos may have been deleted there.
        .task(id: coordinator.path.isEmpty) {
            guard coordinator.path.isEmpty else { return }
            await viewModel.load()
        }
    }
}
