import SwiftUI

struct PassportLeroStampView: View {
    private static let tilt = 4.2
    private static let frameCenter = CGPoint(x: 266.49, y: 159.5)
    private static let figureCenter = CGPoint(x: 270.11, y: 147.31)
    private static let textCenter = CGPoint(x: 265.57, y: 184.08)

    var body: some View {
        ZStack {
            Image("PassportLeroFrame")
                .resizable()
                .frame(width: 108.206, height: 108.173)
                .rotationEffect(.degrees(Self.tilt))
                .position(Self.frameCenter)

            Image("PassportLeroFigure")
                .resizable()
                .frame(width: 66.221, height: 53.325)
                .rotationEffect(.degrees(Self.tilt))
                .position(Self.figureCenter)

            Text("passport.stamp.name")
                .font(.system(size: 26.26, weight: .black, design: .rounded))
                .foregroundStyle(Color.brandBlue500)
                .fixedSize()
                .rotationEffect(.degrees(Self.tilt))
                .position(Self.textCenter)
        }
        .accessibilityHidden(true)
    }
}
