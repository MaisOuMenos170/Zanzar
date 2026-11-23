import SwiftUI

/// What a list shows while it loads: cards that shine, in place of a spinner.
struct ListLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<5, id: \.self) { _ in
                SkeletonBlock(height: 88)
            }
        }
        .shimmering()
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("list.loading.accessibilityLabel"))
    }
}

#Preview {
    ListLoadingView()
        .padding()
        .background(Color.profileBackground)
}
