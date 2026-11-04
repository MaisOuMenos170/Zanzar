import SwiftUI

/// "Add a photo": quieter than the check-in button, which stays the main action of the screen.
struct PlaceDetailAddPhotoButton: View {
    let hasCheckedIn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("placeDetail.addPhotoButton.title", systemImage: "camera")
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .overlay {
                    Capsule()
                        .strokeBorder(Color("PlaceDetailCheckInDoneBorder"), lineWidth: 1)
                }
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(hasCheckedIn
            ? LocalizedStringKey("placeDetail.addPhotoButton.verifiedHint")
            : LocalizedStringKey("placeDetail.addPhotoButton.hint")))
    }
}
