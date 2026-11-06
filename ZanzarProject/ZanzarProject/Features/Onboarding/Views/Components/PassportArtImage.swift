import SwiftUI

/// Draws one `PassportArtPiece` at its place on the illustration canvas.
struct PassportArtImage: View {
    let piece: PassportArtPiece

    var body: some View {
        Image(piece.name)
            .resizable()
            .frame(width: piece.size.width, height: piece.size.height)
            .rotationEffect(.degrees(piece.rotation))
            .position(piece.center)
    }
}
