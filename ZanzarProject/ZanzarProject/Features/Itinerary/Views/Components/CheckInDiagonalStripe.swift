import SwiftUI

/// One of the soft diagonal bars drawn behind the check-in home's buttons and place tiles (Figma "checkin v2").
/// Figma gives each bar as a rectangle rotated -43.33° inside a box at a fixed spot of its parent, so the same
/// three numbers are kept here: the bar, the box it rotates into and where that box sits.
struct CheckInDiagonalStripe: View {
    let bar: CGSize
    let box: CGSize
    let origin: CGPoint
    let color: Color

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: bar.width, height: bar.height)
            .rotationEffect(.degrees(-43.33))
            .frame(width: box.width, height: box.height)
            .position(x: origin.x + box.width / 2, y: origin.y + box.height / 2)
    }
}
