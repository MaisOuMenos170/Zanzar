import SwiftUI

/// A gray shape standing in for something that is still loading: a card, a photo, a line of text.
struct SkeletonBlock: View {
    var width: CGFloat?
    var height: CGFloat
    var cornerRadius: CGFloat = 16

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.brandNeutral200.opacity(0.85))
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }
}

/// A few lines of text, the last one shorter.
struct SkeletonLines: View {
    var count = 3
    var lineHeight: CGFloat = 12

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                SkeletonBlock(height: lineHeight, cornerRadius: lineHeight / 2)
                    .padding(.trailing, index == count - 1 ? 80 : 0)
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        SkeletonBlock(width: 160, height: 20, cornerRadius: 10)
        SkeletonBlock(height: 149)
        SkeletonLines()
    }
    .padding()
    .shimmering()
}
