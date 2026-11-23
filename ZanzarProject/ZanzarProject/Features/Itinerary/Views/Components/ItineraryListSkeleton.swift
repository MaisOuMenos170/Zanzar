import SwiftUI

/// The check-in home while it loads: where "Check-in", the featured roteiros and the nearby places will be.
struct ItineraryListSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 16) {
                    SkeletonBlock(width: 110, height: 24, cornerRadius: 12)
                    SkeletonBlock(height: 135)
                }

                VStack(alignment: .leading, spacing: 16) {
                    SkeletonBlock(width: 180, height: 24, cornerRadius: 12)
                    VStack(spacing: 8) {
                        SkeletonBlock(height: 149)
                        SkeletonBlock(height: 149)
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    SkeletonBlock(width: 150, height: 24, cornerRadius: 12)
                    Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                        ForEach(0..<2, id: \.self) { _ in
                            GridRow {
                                SkeletonBlock(height: 124)
                                SkeletonBlock(height: 124)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .shimmering()
        }
        .scrollDisabled(true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("itinerary.loadingIndicator.title"))
    }
}

#Preview {
    ItineraryListSkeleton()
        .background(Color.profileBackground)
}
