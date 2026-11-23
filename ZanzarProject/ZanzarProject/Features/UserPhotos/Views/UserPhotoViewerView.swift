import SwiftUI

struct UserPhotoViewerView: View {
    let photo: UserPhoto

    var body: some View {
        PhotoViewerView(
            url: photo.viewerURL,
            title: photo.placeName ?? L10n.string("userPhotos.myPhotos.unknownPlace")
        )
    }
}
