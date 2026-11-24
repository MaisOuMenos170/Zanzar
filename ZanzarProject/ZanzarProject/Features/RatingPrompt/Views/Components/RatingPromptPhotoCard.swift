import SwiftUI

/// The dashed box of the rating sheet where a photo of the place can be added (Figma "Avaliação", node 2020:9741):
/// the category chip on top, a picture placeholder and the "Adicionar foto" button in the corner.
struct RatingPromptPhotoCard: View {
    /// Localization key of the place's category; no chip when the place has none on record.
    let categoryTitleKey: String?
    let onAddPhoto: () -> Void

    var body: some View {
        // The rating sheet only opens for a place the user checked in at, so the photo is a verified one.
        PlacePhotoCard(
            tags: categoryTitleKey.map { [L10n.string($0)] } ?? [],
            addPhotoHint: "placeDetail.addPhotoButton.verifiedHint",
            onAddPhoto: onAddPhoto
        )
    }
}

#Preview {
    RatingPromptPhotoCard(categoryTitleKey: "placeDetail.tag.park") {}
        .padding()
}
