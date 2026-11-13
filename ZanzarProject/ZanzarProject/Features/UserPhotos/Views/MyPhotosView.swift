import SwiftUI

/// The user's photos and where each stands. Reached from the profile.
struct MyPhotosView: View {
    @State private var viewModel = MyPhotosViewModel()
    @State private var photoBeingViewed: UserPhoto?

    var body: some View {
        Group {
            if viewModel.photos.isEmpty && viewModel.hasLoaded {
                ContentUnavailableView(
                    "userPhotos.myPhotos.empty.title",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("userPhotos.myPhotos.empty.message")
                )
            } else if viewModel.photos.isEmpty {
                ProgressView()
            } else {
                List {
                    Section {
                        ForEach(viewModel.photos) { photo in
                            Button {
                                photoBeingViewed = photo
                            } label: {
                                MyPhotoRow(photo: photo)
                                    .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("userPhotos.myPhotos.openHint")
                            .swipeActions { deleteButton(for: photo) }
                                .contextMenu { deleteButton(for: photo) }
                        }
                    } footer: {
                        Text("userPhotos.myPhotos.footer")
                    }
                }
            }
        }
        .navigationTitle("userPhotos.myPhotos.title")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .fullScreenCover(item: $photoBeingViewed) { photo in
            UserPhotoViewerView(photo: photo)
        }
        .alert(
            "userPhotos.myPhotos.deleteConfirmation.title",
            isPresented: deletionIsPresented,
            presenting: viewModel.photoPendingDeletion
        ) { photo in
            Button("userPhotos.myPhotos.deleteConfirmation.confirmButton.title", role: .destructive) {
                Task { await viewModel.delete(photo) }
            }
            Button("userPhotos.myPhotos.deleteConfirmation.cancelButton.title", role: .cancel) {}
        } message: { _ in
            Text("userPhotos.myPhotos.deleteConfirmation.message")
        }
        .alert("userPhotos.myPhotos.errorAlert.title", isPresented: errorIsPresented) {
            Button("userPhotos.myPhotos.errorAlert.dismissButton.title", role: .cancel) {}
        } message: {
            if let message = viewModel.errorMessage { Text(message) }
        }
    }

    private func deleteButton(for photo: UserPhoto) -> some View {
        Button("userPhotos.myPhotos.deleteButton.title", systemImage: "trash", role: .destructive) {
            viewModel.photoPendingDeletion = photo
        }
    }

    private var deletionIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.photoPendingDeletion != nil },
            set: { if !$0 { viewModel.photoPendingDeletion = nil } }
        )
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil && viewModel.hasLoaded },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}
