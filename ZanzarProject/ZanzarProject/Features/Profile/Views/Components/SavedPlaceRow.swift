import SwiftUI

/// One saved place of the list (Figma "Perfil", node 2678:2225): its photo, name and the day it was saved, and a
/// trash button to take it off the list.
struct SavedPlaceRow: View {
    let place: SavedPlace
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // The link takes the photo and the texts; the trash button beside it is its own target.
            NavigationLink(value: Route.placeDetail(place.mapPlace(category: nil))) {
                HStack(spacing: 12) {
                    photo

                    VStack(alignment: .leading, spacing: 6) {
                        Text(place.displayName)
                            .typography(.subtitle2)
                            .foregroundStyle(Color.black)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text(place.savedAt, format: .dateTime.day(.twoDigits).month(.twoDigits).year())
                            .typography(.caption1)
                            .foregroundStyle(Color.brandNeutral600)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("profile.checkInCard.openDetailsHint")

            Button(action: onRemove) {
                Image(systemName: "trash")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.brandErrorRed)
                    .padding(4)
                    .contentShape(.rect.inset(by: -8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("savedPlaces.remove.accessibilityLabel \(place.displayName)"))
        }
        .padding(12)
    }

    private var photo: some View {
        PlaceRemoteImage(photoURL: place.imageURL) {
            ZStack {
                Color.brandPurple100
                Image(systemName: "photo")
                    .foregroundStyle(Color.brandPurple300)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(.rect(cornerRadius: 8))
    }
}
