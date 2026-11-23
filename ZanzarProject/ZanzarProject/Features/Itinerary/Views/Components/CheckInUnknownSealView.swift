import SwiftUI

struct CheckInUnknownSealView: View {
    enum Style {
        case onColor
        case onTicket
    }

    var size: CGFloat = 83
    var style = Style.onColor

    var body: some View {
        ZStack {
            switch style {
            case .onColor:
                Image(.checkInSealUnknownRing)
                    .resizable()
                    .frame(width: size * 88.3916 / 83, height: size * 88.3916 / 83)
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: size * 52 / 83))
                    .foregroundStyle(.white.opacity(0.5))
            case .onTicket:
                Image(.itineraryTicketUnknownRing)
                    .resizable()
                    .frame(width: size * 47.6968 / 44.787, height: size * 47.6968 / 44.787)
                Image(systemName: "questionmark")
                    .font(.system(size: size * 0.45, weight: .bold))
                    .foregroundStyle(Self.ticketGray)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private static let ticketGray = Color(red: 220 / 255, green: 220 / 255, blue: 220 / 255)
}

#Preview {
    HStack {
        CheckInUnknownSealView()
        CheckInUnknownSealView(size: 44.787)
        CheckInUnknownSealView(size: 44.787, style: .onTicket)
    }
    .padding()
    .background(Color.brandPurple200)
}
