import SwiftUI

/// The dashed box of the rating sheet where a photo of the place can be added (Figma "Avaliação", node 2020:9741):
/// the category chip on top, a picture placeholder and the "Adicionar foto" button in the corner.
struct RatingPromptPhotoCard: View {
    /// Localization key of the place's category; no chip when the place has none on record.
    let categoryTitleKey: String?
    let onAddPhoto: () -> Void

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.brandNeutral50)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.brandPurple100, style: StrokeStyle(lineWidth: 3, dash: [9, 6]))
            }
            .frame(height: 168)
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.brandPurple100)
                    .accessibilityHidden(true)
            }
            .overlay(alignment: .topLeading) {
                if let categoryTitleKey {
                    chip(LocalizedStringKey(categoryTitleKey))
                        .padding(9.5)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                addPhotoButton
                    .padding(9.5)
            }
    }

    private func chip(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.system(size: 12))
            .foregroundStyle(Color.brandNeutral600)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
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
    }

    private func stripe(bar: CGSize, box: CGSize, origin: CGPoint) -> some View {
        DiagonalStripe(bar: bar, box: box, origin: origin, color: .black.opacity(0.03))
    }
}

#Preview {
    RatingPromptPhotoCard(categoryTitleKey: "placeDetail.tag.park") {}
        .padding()
}
