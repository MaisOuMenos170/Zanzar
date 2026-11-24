import SwiftUI

/// One exported piece of the welcome illustration, drawn at its spot. It fills the space it is given, so
/// turning or scaling it uses the container as the frame of reference (see `WelcomeArt.Pivot`).
struct WelcomeLayer: View {
    let image: String
    let frame: CGRect

    init(_ image: String, _ frame: CGRect) {
        self.image = image
        self.frame = frame
    }

    var body: some View {
        Image(decorative: image)
            .resizable()
            .frame(width: frame.width, height: frame.height)
            .position(x: frame.midX, y: frame.midY)
    }

    func center(in size: CGSize) -> UnitPoint {
        UnitPoint(x: frame.midX / size.width, y: frame.midY / size.height)
    }
}
