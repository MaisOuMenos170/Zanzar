import SwiftUI

struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonBlock(width: 40, height: 40, cornerRadius: 20)
            VStack(alignment: .leading, spacing: 6) {
                SkeletonBlock(width: 170, height: 13, cornerRadius: 6.5)
                SkeletonBlock(width: 110, height: 11, cornerRadius: 5.5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SkeletonRows: View {
    var count = 3

    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<count, id: \.self) { _ in
                SkeletonRow()
            }
        }
        .shimmering()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("list.loading.accessibilityLabel"))
    }
}

#Preview {
    SkeletonRows()
        .padding()
}
