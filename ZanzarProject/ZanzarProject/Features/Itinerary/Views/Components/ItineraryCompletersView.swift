import SwiftUI

/// "40 pessoas completaram esse roteiro", with the faces of the last ones to finish it and how many more there are
/// (Figma "checkin v2", node 2313:6928).
struct ItineraryCompletersView: View {
    let avatars: [Avatar]
    let completedCount: Int

    /// The faces that fit before the "+N" bubble.
    private static let visibleAvatars = 3

    private var shown: [Avatar] {
        Array(avatars.prefix(Self.visibleAvatars))
    }

    /// The people who finished it and have no face on the row.
    private var others: Int {
        max(0, completedCount - shown.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: -8) {
                ForEach(shown.indices, id: \.self) { index in
                    AvatarPortraitView(avatar: shown[index])
                        .frame(width: 24, height: 24)
                        .overlay { Circle().strokeBorder(.white, lineWidth: 1.205) }
                }
                if others > 0 {
                    Text(others < 100 ? "+\(others)" : "99+")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .frame(minWidth: 25, minHeight: 24)
                        .background(Color.brandPurple500, in: .capsule)
                        .overlay { Capsule().strokeBorder(.white, lineWidth: 1.205) }
                }
            }
            .accessibilityHidden(true)

            Text("itinerary.detail.completedBy \(completedCount)")
                .font(.caption2)
                .foregroundStyle(.black)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ItineraryCompletersView(avatars: [.placeholder, .placeholder, .placeholder], completedCount: 40)
        .padding()
}
