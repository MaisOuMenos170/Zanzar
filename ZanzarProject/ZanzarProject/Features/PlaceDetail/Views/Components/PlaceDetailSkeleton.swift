import SwiftUI

/// The place detail while it loads: the name, the photo box, the check-in button, the text and the numbers.
struct PlaceDetailSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonBlock(width: 240, height: 26, cornerRadius: 13)
                    SkeletonBlock(width: 160, height: 14, cornerRadius: 7)
                }
                SkeletonBlock(height: .placePhotoCardHeight)
                SkeletonBlock(height: 52, cornerRadius: 26)
            }

            SkeletonLines(count: 4, lineHeight: 14)

            SkeletonBlock(height: 96)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .frame(maxHeight: .infinity, alignment: .top)
        .shimmering()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("placeDetail.loadingIndicator.title"))
    }
}

#Preview {
    PlaceDetailSkeleton()
        .background(Color.profileBackground)
}
