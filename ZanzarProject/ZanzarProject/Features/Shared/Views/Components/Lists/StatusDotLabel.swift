import SwiftUI

struct StatusDotLabel: View {
    let title: LocalizedStringKey
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
            Text(title)
                .typography(.caption1)
                .foregroundStyle(Color.brandNeutral900)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
