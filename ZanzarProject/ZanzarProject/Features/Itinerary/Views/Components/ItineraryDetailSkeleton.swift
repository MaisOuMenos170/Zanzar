import SwiftUI

/// The roteiro sheet while it loads, laid out like the sheet: title, who finished it, the ticket and the places.
struct ItineraryDetailSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    SkeletonBlock(width: 220, height: 26, cornerRadius: 13)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: -8) {
                            ForEach(0..<3, id: \.self) { _ in
                                SkeletonBlock(width: 24, height: 24, cornerRadius: 12)
                            }
                        }
                        SkeletonBlock(width: 190, height: 11, cornerRadius: 5.5)
                    }
                    SkeletonLines(count: 2, lineHeight: 14)
                }
                .padding(.horizontal, 8)

                SkeletonBlock(height: 149)
            }

            VStack(alignment: .leading, spacing: 16) {
                SkeletonBlock(width: 200, height: 18, cornerRadius: 9)
                HStack(spacing: 8) {
                    SkeletonBlock(height: 124)
                    SkeletonBlock(height: 124)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 36)
        .frame(maxHeight: .infinity, alignment: .top)
        .shimmering()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("itinerary.detail.loadingIndicator.title"))
    }
}

#Preview {
    ItineraryDetailSkeleton()
}
