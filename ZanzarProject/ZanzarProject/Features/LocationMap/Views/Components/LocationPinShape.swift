import SwiftUI

/// Map pin silhouette traced from the Figma design (node 290:1994).
struct LocationPinShape: Shape {
    private static let designSize = CGSize(width: 40.0769, height: 47.7106)

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
        path.move(to: CGPoint(x: 20.0385, y: 0))
        path.addCurve(
            to: CGPoint(x: 40.0769, y: 20.0385),
            control1: CGPoint(x: 31.1054, y: 0),
            control2: CGPoint(x: 40.0769, y: 8.97153)
        )
        path.addCurve(
            to: CGPoint(x: 27.3538, y: 38.6997),
            control1: CGPoint(x: 40.0769, y: 28.5238),
            control2: CGPoint(x: 34.8027, y: 35.7774)
        )
        path.addLine(to: CGPoint(x: 21.1798, y: 47.1387))
        path.addCurve(
            to: CGPoint(x: 20.6815, y: 47.5591),
            control1: CGPoint(x: 21.0511, y: 47.3154),
            control2: CGPoint(x: 20.8802, y: 47.4596)
        )
        path.addCurve(
            to: CGPoint(x: 20.0385, y: 47.7106),
            control1: CGPoint(x: 20.4829, y: 47.6587),
            control2: CGPoint(x: 20.2623, y: 47.7106)
        )
        path.addCurve(
            to: CGPoint(x: 19.3954, y: 47.5591),
            control1: CGPoint(x: 19.8146, y: 47.7106),
            control2: CGPoint(x: 19.594, y: 47.6587)
        )
        path.addCurve(
            to: CGPoint(x: 18.8971, y: 47.1387),
            control1: CGPoint(x: 19.1967, y: 47.4596),
            control2: CGPoint(x: 19.0258, y: 47.3154)
        )
        path.addLine(to: CGPoint(x: 12.7231, y: 38.6997))
        path.addCurve(
            to: CGPoint(x: 0, y: 20.0385),
            control1: CGPoint(x: 5.27418, y: 35.7774),
            control2: CGPoint(x: 0, y: 28.5238)
        )
        path.addCurve(
            to: CGPoint(x: 20.0385, y: 0),
            control1: CGPoint(x: 0, y: 8.97153),
            control2: CGPoint(x: 8.97152, y: 0)
        )
        path.closeSubpath()
        return path
    }
}
