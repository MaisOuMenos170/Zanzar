import SwiftUI

/// Map pin silhouette from Figma node 860:4030 (46×54).
struct LocationPinShape: Shape {
    private static let designSize = CGSize(width: 46, height: 54)

    func path(in rect: CGRect) -> Path {
        Self.designPath().applying(
            CGAffineTransform(
                scaleX: rect.width / Self.designSize.width,
                y: rect.height / Self.designSize.height
            )
        )
    }

    private static func designPath() -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 23, y: 0))
        path.addCurve(
            to: CGPoint(x: 46, y: 22.68),
            control1: CGPoint(x: 35.7025, y: 0),
            control2: CGPoint(x: 46, y: 10.1542)
        )
        path.addCurve(
            to: CGPoint(x: 31.3965, y: 43.8012),
            control1: CGPoint(x: 46, y: 32.284),
            control2: CGPoint(x: 39.9463, y: 40.4937)
        )
        path.addLine(to: CGPoint(x: 24.31, y: 53.3527))
        path.addCurve(
            to: CGPoint(x: 23.7381, y: 53.8285),
            control1: CGPoint(x: 24.1623, y: 53.5527),
            control2: CGPoint(x: 23.9661, y: 53.7159)
        )
        path.addCurve(
            to: CGPoint(x: 23, y: 54),
            control1: CGPoint(x: 23.5101, y: 53.9412),
            control2: CGPoint(x: 23.2569, y: 54)
        )
        path.addCurve(
            to: CGPoint(x: 22.2619, y: 53.8285),
            control1: CGPoint(x: 22.7431, y: 54),
            control2: CGPoint(x: 22.4899, y: 53.9412)
        )
        path.addCurve(
            to: CGPoint(x: 21.69, y: 53.3527),
            control1: CGPoint(x: 22.0339, y: 53.7159),
            control2: CGPoint(x: 21.8377, y: 53.5527)
        )
        path.addLine(to: CGPoint(x: 14.6035, y: 43.8012))
        path.addCurve(
            to: CGPoint(x: 0, y: 22.68),
            control1: CGPoint(x: 6.05366, y: 40.4937),
            control2: CGPoint(x: 0, y: 32.284)
        )
        path.addCurve(
            to: CGPoint(x: 23, y: 0),
            control1: CGPoint(x: 0, y: 10.1542),
            control2: CGPoint(x: 10.2975, y: 0)
        )
        path.closeSubpath()
        return path
    }
}
