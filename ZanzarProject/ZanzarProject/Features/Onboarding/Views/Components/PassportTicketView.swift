import SwiftUI

struct PassportTicketView: View {
    private static let size = CGSize(width: 209.639, height: 415.77)
    private static let center = CGPoint(x: 268.85, y: 222.82)
    private static let bars: [(x: CGFloat, width: CGFloat)] = [
        (44.73, 7.32), (55.1, 2.44), (58.76, 2.44), (65.47, 10.37), (79.5, 6.71), (91.7, 2.44), (100.24, 2.44),
        (106.95, 7.93), (117.32, 2.44), (120.99, 2.44), (127.7, 9.76), (141.72, 6.71), (153.93, 2.44), (162.46, 2.44)
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white

            Color.brandOrange500
                .frame(width: 23.68)
            Color.brandOrange500
                .frame(width: 22.81)
                .frame(maxWidth: .infinity, alignment: .trailing)

            ForEach(Self.bars, id: \.x) { bar in
                Rectangle()
                    .fill(.black)
                    .frame(width: bar.width, height: 32)
                    .offset(x: bar.x, y: 28.95)
            }

            Text("passport.ticket.city")
                .font(.system(size: 38.385, weight: .black, design: .rounded))
                .foregroundStyle(.black)
                .fixedSize()
                .rotationEffect(.degrees(90))
                .position(x: 154.18, y: 208.28)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipShape(.rect(cornerRadius: 21.052))
        .rotationEffect(.degrees(3.45))
        .position(Self.center)
        .accessibilityHidden(true)
    }
}
