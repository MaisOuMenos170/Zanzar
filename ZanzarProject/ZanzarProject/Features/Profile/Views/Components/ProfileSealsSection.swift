import SwiftUI

struct ProfileSealsSection: View {
    let categories: [ZanzarPlaceCategory]
    let onSeeMore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProfileSectionHeader(title: "profile.sealsSection.title", onSeeMore: onSeeMore)

            if categories.isEmpty {
                ListEmptyState(message: "profile.sealsSection.empty")
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { category in
                            PlaceCategorySealView(category: category, size: 90)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                // Seals scrolling out of the 16pt margin are not cut at its edge, they slide off the screen.
                .scrollClipDisabled()
            }
        }
    }
}

#Preview {
    ProfileSealsSection(categories: [.park, .restaurant, .museum, .tourist, .bar], onSeeMore: {})
        .padding()
        .background(Color.profileBackground)
}
