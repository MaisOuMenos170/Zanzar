import SwiftUI

/// A white rounded card whose rows are separated by a hairline, like the settings and photo lists of the profile.
/// Every child of `content` (including the ones a `ForEach` makes) is a row.
struct ListCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            Group(subviews: content) { rows in
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    if index > 0 {
                        Rectangle()
                            .fill(Color.brandPurple100)
                            .frame(height: 1)
                            .accessibilityHidden(true)
                    }
                    row
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.brandNeutral50)
        .clipShape(.rect(cornerRadius: 16))
    }
}
