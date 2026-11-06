import SwiftUI

/// Stacks the avatar's layer images into a face, laid out on the design's 397×297 canvas.
/// Eyelashes and hair are optional (`Avatar.none` draws nothing).
/// Hair is split in a part behind the face and one in front.
struct AvatarFaceView: View {
    let avatar: Avatar

    private static let centering = CGSize(width: 1.5, height: -10)
    private static let compositionScale: CGFloat = 0.88

    private struct Layer {
        let folder: String
        let id: Int
        let origin: CGPoint
        let width: CGFloat
    }

    private static let canvas = CGSize(width: 397, height: 297)

    private var layers: [Layer] {
        var layers: [Layer] = []
        let hair = avatar.hair == Avatar.none ? nil : AvatarHairLayout.placement(for: avatar.hair)
        if let back = hair?.back {
            layers.append(Layer(folder: "CabelosFundo", id: avatar.hair, origin: back.origin, width: back.width))
        }
        layers.append(Layer(folder: "Pele", id: avatar.skin, origin: CGPoint(x: 28, y: 56), width: 338))
        if let hair {
            layers.append(Layer(folder: "Cabelos", id: avatar.hair, origin: hair.origin, width: hair.width))
        }
        layers.append(Layer(folder: "Sobrancelhas", id: avatar.eyebrow, origin: CGPoint(x: 162, y: 165), width: 70))
        layers.append(Layer(folder: "Olhos", id: avatar.eyes, origin: CGPoint(x: 130, y: 184), width: 134))
        if avatar.eyelash != Avatar.none {
            layers.append(Layer(folder: "Cilios", id: avatar.eyelash, origin: CGPoint(x: 119, y: 197), width: 156))
        }
        return layers
    }

    var body: some View {
        Color.clear
            .aspectRatio(Self.canvas.width / Self.canvas.height, contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    let scale = proxy.size.width / Self.canvas.width
                    ZStack(alignment: .topLeading) {
                        ForEach(layers, id: \.folder) { layer in
                            Image("\(layer.folder)/\(layer.id)")
                                .resizable()
                                .scaledToFit()
                                .frame(width: layer.width * scale)
                                .offset(x: layer.origin.x * scale, y: layer.origin.y * scale)
                        }
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                    .scaleEffect(Self.compositionScale)
                    .offset(x: Self.centering.width * scale, y: Self.centering.height * scale)
                }
            }
            .accessibilityElement()
            .accessibilityLabel("avatar.face.accessibilityLabel")
    }
}

#Preview {
    AvatarFaceView(avatar: .placeholder)
        .padding()
}
