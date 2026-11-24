import SwiftUI

/// Speech-bubble "label" silhouette from the Figma pin family B (node 1929:462): a rounded rectangle with a
/// small tail centered at the bottom, drawn as one continuous outline so a stroke follows the tail too.
/// The tail tip sits on the bottom edge of the rect, so the bounds are the body plus the tail. A zero
/// `tailHeight` gives a plain rounded rectangle.
struct LocationLabelShape: Shape {
    var cornerRadius: CGFloat
    var tailWidth: CGFloat
    var tailHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        let bodyBottom = rect.maxY - tailHeight
        let radius = min(cornerRadius, rect.width / 2, (bodyBottom - rect.minY) / 2)

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addArc(
            tangent1End: CGPoint(x: rect.maxX, y: rect.minY),
            tangent2End: CGPoint(x: rect.maxX, y: rect.minY + radius),
            radius: radius
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: bodyBottom - radius))
        path.addArc(
            tangent1End: CGPoint(x: rect.maxX, y: bodyBottom),
            tangent2End: CGPoint(x: rect.maxX - radius, y: bodyBottom),
            radius: radius
        )
        if tailHeight > 0 {
            path.addLine(to: CGPoint(x: rect.midX + tailWidth / 2, y: bodyBottom))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX - tailWidth / 2, y: bodyBottom))
        }
        path.addLine(to: CGPoint(x: rect.minX + radius, y: bodyBottom))
        path.addArc(
            tangent1End: CGPoint(x: rect.minX, y: bodyBottom),
            tangent2End: CGPoint(x: rect.minX, y: bodyBottom - radius),
            radius: radius
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addArc(
            tangent1End: CGPoint(x: rect.minX, y: rect.minY),
            tangent2End: CGPoint(x: rect.minX + radius, y: rect.minY),
            radius: radius
        )
        path.closeSubpath()
        return path
    }
}
