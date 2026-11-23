import SwiftUI

/// The 168pt photo box of the place detail and of the rating sheet (Figma nodes 2005:9658 and 2020:9741).
/// Without photos it is a dashed placeholder; with photos it shows them instead. On top of either go the tags,
/// an optional accessory in the opposite corner (the bookmark) and the "Adicionar foto" pill at the bottom.
struct PlacePhotoCard<Photos: View, Accessory: View>: View {
    let tags: [String]
    let showsPhotos: Bool
    let addPhotoHint: LocalizedStringKey
    let onAddPhoto: () -> Void
    private let accessory: Accessory
    private let photos: Photos

    private static var cornerRadius: CGFloat { 16 }
    /// The tags and buttons sit this far from the edge of the dashed border (Figma: 9.5pt).
    private static var inset: CGFloat { 9.5 }

    init(
        tags: [String],
        showsPhotos: Bool = false,
        addPhotoHint: LocalizedStringKey = "placeDetail.addPhotoButton.hint",
        onAddPhoto: @escaping () -> Void,
        @ViewBuilder accessory: () -> Accessory,
        @ViewBuilder photos: () -> Photos
    ) {
        self.tags = tags
        self.showsPhotos = showsPhotos
        self.addPhotoHint = addPhotoHint
        self.onAddPhoto = onAddPhoto
        self.accessory = accessory()
        self.photos = photos()
    }

    var body: some View {
        ZStack {
            if showsPhotos {
                photos
                    .clipShape(.rect(cornerRadius: Self.cornerRadius))
            } else {
                placeholder
            }
        }
        .frame(height: .placePhotoCardHeight)
        .overlay(alignment: .top) {
            HStack(alignment: .top, spacing: 4) {
                ForEach(tags.prefix(2), id: \.self) { chip($0) }
                Spacer(minLength: 8)
                accessory
            }
            .padding(Self.inset)
        }
        .overlay(alignment: .bottomTrailing) {
            addPhotoButton
                .padding(Self.inset)
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: Self.cornerRadius)
            .fill(Color.brandNeutral50)
            .overlay {
                RoundedRectangle(cornerRadius: Self.cornerRadius)
                    .strokeBorder(Color.brandPurple100, style: StrokeStyle(lineWidth: 3, dash: [9, 6]))
            }
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.brandPurple100)
                    .accessibilityHidden(true)
            }
    }

    private func chip(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12))
            .foregroundStyle(Color.brandNeutral600)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            // Opaque, so the tag stays readable over a photo.
            .background(Color.brandNeutral50, in: .capsule)
            .overlay {
                Capsule()
                    .strokeBorder(Color.brandNeutral200, lineWidth: 1)
            }
    }

    private var addPhotoButton: some View {
        Button(action: onAddPhoto) {
            Label("placeDetail.addPhotoButton.title", systemImage: "camera")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    ZStack {
                        Color.brandCoral500
                        stripe(bar: CGSize(width: 91.141, height: 14.883),
                               box: CGSize(width: 76.512, height: 73.363), origin: CGPoint(x: 19.9, y: -17))
                        stripe(bar: CGSize(width: 91.141, height: 7.798),
                               box: CGSize(width: 71.651, height: 68.21), origin: CGPoint(x: 66.86, y: -11.85))
                        stripe(bar: CGSize(width: 91.141, height: 6.707),
                               box: CGSize(width: 70.902, height: 67.416), origin: CGPoint(x: -8.92, y: -28.45))
                    }
                }
                .clipShape(.rect(cornerRadius: 16))
                .contentShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityHint(Text(addPhotoHint))
    }

    private func stripe(bar: CGSize, box: CGSize, origin: CGPoint) -> some View {
        DiagonalStripe(bar: bar, box: box, origin: origin, color: .black.opacity(0.03))
    }
}

extension CGFloat {
    /// The height of `PlacePhotoCard`, for the photos that go inside it.
    static let placePhotoCardHeight: CGFloat = 168
}

extension PlacePhotoCard where Photos == EmptyView, Accessory == EmptyView {
    /// The empty box: no photos and nothing in the corner.
    init(
        tags: [String],
        addPhotoHint: LocalizedStringKey = "placeDetail.addPhotoButton.hint",
        onAddPhoto: @escaping () -> Void
    ) {
        self.init(
            tags: tags,
            addPhotoHint: addPhotoHint,
            onAddPhoto: onAddPhoto,
            accessory: { EmptyView() },
            photos: { EmptyView() }
        )
    }
}

#Preview {
    PlacePhotoCard(
        tags: ["Parque", "Cartão-postal"],
        onAddPhoto: {},
        accessory: {
            Image(systemName: "bookmark")
                .foregroundStyle(Color.brandOrange600)
        },
        photos: { EmptyView() }
    )
    .padding()
}
