import SwiftUI

/// The user's photos as rows of a white card, with the viewer, the delete confirmation and the error alert
/// every list of photos needs. Used by the profile and by "all photos".
struct UserPhotoListCard: View {
    let photos: [UserPhoto]
    @Bindable var viewModel: MyPhotosViewModel

    @State private var photoBeingViewed: UserPhoto?
    @Namespace private var zoomNamespace

    var body: some View {
        ListCard {
            ForEach(photos) { photo in
                UserPhotoRow(
                    photo: photo,
                    onOpen: { photoBeingViewed = photo },
                    onDelete: { viewModel.photoPendingDeletion = photo },
                    zoomNamespace: zoomNamespace
                )
            }
        }
        .fullScreenCover(item: $photoBeingViewed) { photo in
            // The system's zoom: the photo grows out of its thumbnail and shrinks back into it.
            UserPhotoViewerView(photo: photo)
                .navigationTransition(.zoom(sourceID: photo.id, in: zoomNamespace))
        }
        // Cancel is the filled button (the default action) and the destructive one is red text on gray, as in the
        // Figma alert. Cancel keeps its `.cancel` role: without one the system adds its own extra "Cancelar"
        // button, and the system always puts the cancel button last.
        .alert(
            "userPhotos.myPhotos.deleteConfirmation.title",
            isPresented: deletionIsPresented,
            presenting: viewModel.photoPendingDeletion
        ) { photo in
            Button("userPhotos.myPhotos.deleteConfirmation.confirmButton.title", role: .destructive) {
                Task { await viewModel.delete(photo) }
            }
            Button("userPhotos.myPhotos.deleteConfirmation.cancelButton.title", role: .cancel) {}
                .keyboardShortcut(.defaultAction)
        } message: { _ in
            Text("userPhotos.myPhotos.deleteConfirmation.message")
        }
        .alert("userPhotos.myPhotos.errorAlert.title", isPresented: errorIsPresented) {
            Button("userPhotos.myPhotos.errorAlert.dismissButton.title", role: .cancel) {}
        } message: {
            if let message = viewModel.errorMessage { Text(message) }
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
