import SwiftUI

/// The profile while it loads: the numbers, the seals and the latest check-ins.
struct ProfileSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            SkeletonBlock(height: 96)

            VStack(alignment: .leading, spacing: 16) {
                SkeletonBlock(width: 140, height: 24, cornerRadius: 12)
                HStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonBlock(width: 72, height: 72, cornerRadius: 36)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                SkeletonBlock(width: 180, height: 24, cornerRadius: 12)
                SkeletonBlock(height: 120)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .frame(maxHeight: .infinity, alignment: .top)
        .shimmering()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("profile.loadingIndicator.title"))
    }
}

#Preview {
    ProfileSkeleton()
        .background(Color.profileBackground)
}
