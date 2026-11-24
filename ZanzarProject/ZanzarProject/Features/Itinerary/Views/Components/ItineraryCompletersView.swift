import SwiftUI

struct ItineraryCompletersView: View {
    let avatars: [Avatar]
    let completedCount: Int
    let seed: String

    private static let visibleAvatars = 3

    private var shown: [Avatar] {
        Self.faces(avatars: avatars, completedCount: completedCount, seed: seed)
    }

    static func faces(avatars: [Avatar], completedCount: Int, seed: String) -> [Avatar] {
        let real = Array(avatars.prefix(visibleAvatars))
        let missing = max(0, min(visibleAvatars, completedCount) - real.count)
        return real + (0..<missing).map { Avatar.generated(seed: "\(seed)-\(real.count + $0)") }
    }

    private var others: Int {
        max(0, completedCount - shown.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if completedCount > 0 {
                faces
                Text("itinerary.detail.completedBy \(completedCount)")
                    .font(.caption2)
                    .foregroundStyle(.black)
            } else {
                Text("itinerary.detail.completedByNobody")
                    .font(.caption2)
                    .foregroundStyle(.black)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var faces: some View {
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
    }
}

#Preview {
    ItineraryCompletersView(avatars: [], completedCount: 40, seed: "preview")
        .padding()
}
