import SwiftUI

/// Stacks the avatar's layer images into a face, laid out on the design's 397×297 canvas.
/// The hair layer is not drawn yet.
struct AvatarFaceView: View {
    let avatar: Avatar
    /// The backend does not store eyelashes yet, so every face uses the same ones.
    var lashes = 1

    private struct Layer {
        let folder: String
        let id: Int
        let origin: CGPoint
        let width: CGFloat
    }

    private static let canvas = CGSize(width: 397, height: 297)

    private var layers: [Layer] {
        [
            Layer(folder: "Pele", id: avatar.skin, origin: CGPoint(x: 28, y: 56), width: 338),
            Layer(folder: "Sobrancelhas", id: avatar.eyebrow, origin: CGPoint(x: 162, y: 165), width: 70),
            Layer(folder: "Olhos", id: avatar.eyes, origin: CGPoint(x: 130, y: 184), width: 134),
            Layer(folder: "Cilios", id: lashes, origin: CGPoint(x: 119, y: 197), width: 156)
        ]
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
