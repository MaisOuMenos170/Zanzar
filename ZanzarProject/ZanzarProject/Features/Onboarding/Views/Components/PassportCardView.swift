import SwiftUI

/// The passport card on the illustration canvas: border, printed stamps, the user's avatar, name, city and
/// the number of stamps collected. Everything is tilted like the card.
struct PassportCardView: View {
    let avatar: Avatar
    let name: String
    let stampCount: Int

    var body: some View {
        ZStack {
            ForEach(PassportArtPiece.cardFrame) { PassportArtImage(piece: $0) }
            ForEach(PassportArtPiece.cardDecorations) { PassportArtImage(piece: $0) }

            AvatarPortraitView(avatar: avatar, fallbackBackground: Color.avatarBackdrop)
                .frame(width: 142, height: 142)
                .rotationEffect(.degrees(PassportArtPiece.cardTilt))
                .position(x: 124.19, y: 389.37)

            printed("passport.title", size: 18.546, weight: .heavy, at: CGPoint(x: 262.88, y: 324.74))
            printed("passport.nameField.label", size: 11.589, weight: .regular, at: CGPoint(x: 219.22, y: 355.16))
            printed(verbatim: name, size: 15.445, weight: .semibold, maxWidth: 125, at: CGPoint(x: 267.59, y: 369.6))
            printed("passport.cityField.label", size: 11.589, weight: .regular, at: CGPoint(x: 225.37, y: 398.87))
            printed("passport.cityField.value", size: 15.445, weight: .semibold, at: CGPoint(x: 236.66, y: 414.37))
            printed(
                "passport.stamps.label",
                size: 10.107,
                weight: .bold,
                color: .white,
                at: CGPoint(x: 276.99, y: 440.45)
            )
            printed(
                verbatim: stampCount.formatted(),
                size: 15.445,
                weight: .semibold,
                color: Color(white: 0.353),
                at: CGPoint(x: 218.39, y: 466.35)
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("passport.accessibilityLabel \(name) \(stampCount)"))
    }

    private func printed(
        _ key: LocalizedStringKey,
        size: CGFloat,
        weight: Font.Weight,
        color: Color = .brandNeutral950,
        at center: CGPoint
    ) -> some View {
        Text(key)
            .printedStyle(size: size, weight: weight, color: color, center: center)
    }

    private func printed(
        verbatim text: String,
        size: CGFloat,
        weight: Font.Weight,
        color: Color = .brandNeutral950,
        maxWidth: CGFloat? = nil,
        at center: CGPoint
    ) -> some View {
        // Free text (the name) shrinks to fit its line instead of running off the page.
        Text(verbatim: text)
            .lineLimit(1)
            .minimumScaleFactor(maxWidth == nil ? 1 : 0.5)
            .frame(maxWidth: maxWidth, alignment: .leading)
            .printedStyle(size: size, weight: weight, color: color, center: center, fixesSize: maxWidth == nil)
    }
}

private extension View {
    /// Fixed-size rounded text laid on the card, which is a picture and so does not follow Dynamic Type.
    func printedStyle(
        size: CGFloat,
        weight: Font.Weight,
        color: Color,
        center: CGPoint,
        fixesSize: Bool = true
    ) -> some View {
        font(.system(size: size, weight: weight, design: .rounded))
            .foregroundStyle(color)
            .fixedSize(horizontal: fixesSize, vertical: true)
            .rotationEffect(.degrees(PassportArtPiece.cardTilt))
            .position(center)
    }
}
