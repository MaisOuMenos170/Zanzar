import SwiftUI

/// The place screen's photo flows: sending a photo, reporting someone else's photo, blocking its author.
struct PlaceDetailUserPhotoFlows: ViewModifier {
    @Binding var showsPhotoUpload: Bool
    let placeID: String
    let detail: PlaceDetail?
    let reloadUserPhotos: () async -> Void

    @Environment(ToastPresenter.self) private var toastPresenter
    @State private var photoToReport: UserPhotoAttribution?
    @State private var photoToBlock: UserPhotoAttribution?

    func body(content: Content) -> some View {
        content
            .environment(\.userPhotoActionHandler, UserPhotoActionHandler { attribution, action in
                switch action {
                case .report: photoToReport = attribution
                case .blockAuthor: photoToBlock = attribution
                }
            })
            .sheet(
                isPresented: $showsPhotoUpload,
                onDismiss: { Task { await reloadUserPhotos() } },
                content: {
                    if let detail {
                        PhotoUploadSheet(
                            placeID: detail.id,
                            placeName: detail.displayName,
                            fromCheckIn: detail.hasCheckedIn
                        )
                    }
                }
            )
            .sheet(item: $photoToReport) { attribution in
                ReportPhotoSheet(photoID: attribution.photoID, placeID: placeID) {
                    toastPresenter.show(L10n.string("placeDetail.photoReport.sentToast"))
                    Task { await reloadUserPhotos() }
                }
            }
            .confirmationDialog(
                "placeDetail.photoBlock.confirmation.title",
                isPresented: blockConfirmationIsPresented,
                titleVisibility: .visible,
                presenting: photoToBlock
            ) { attribution in
                // The dialog clears `photoToBlock` before this runs, so the photo comes from `presenting`.
                Button("placeDetail.photoBlock.confirmation.confirmButton.title", role: .destructive) {
                    Task { await block(attribution) }
                }
                Button("placeDetail.photoBlock.confirmation.cancelButton.title", role: .cancel) {}
            } message: { _ in
                Text("placeDetail.photoBlock.confirmation.message")
            }
    }

    private var blockConfirmationIsPresented: Binding<Bool> {
        Binding(get: { photoToBlock != nil }, set: { if !$0 { photoToBlock = nil } })
    }

    private func block(_ attribution: UserPhotoAttribution) async {
        let blocker = ReportPhotoViewModel(photoID: attribution.photoID, placeID: placeID)
        await blocker.blockOnly()
        let key = blocker.didFinish ? "placeDetail.photoBlock.doneToast" : "placeDetail.photoBlock.failedToast"
        toastPresenter.show(L10n.string(key))
        await reloadUserPhotos()
    }
}
