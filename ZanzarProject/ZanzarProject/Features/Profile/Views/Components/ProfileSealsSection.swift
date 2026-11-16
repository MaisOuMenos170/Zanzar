import SwiftUI

/// "Selos colecionados": the seals the user has earned, most recent first.
struct ProfileSealsSection: View {
    let categories: [ZanzarPlaceCategory]
    let onSeeMore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ProfileSectionHeader(title: "profile.sealsSection.title", onSeeMore: onSeeMore)

            if categories.isEmpty {
                Text("profile.sealsSection.empty")
                    .typography(.body2)
                    .foregroundStyle(Color.brandNeutral600)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { category in
                            PlaceCategorySealView(category: category, size: 90)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

#Preview {
    ProfileSealsSection(categories: [.park, .restaurant, .museum, .tourist, .bar], onSeeMore: {})
        .padding()
        .background(Color.profileBackground)
}
