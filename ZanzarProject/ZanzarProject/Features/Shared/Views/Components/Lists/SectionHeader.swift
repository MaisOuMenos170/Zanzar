import SwiftUI

struct SectionHeader: View {
    let title: LocalizedStringKey
    let onSeeMore: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .typography(.headline6)
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)

            Button(action: onSeeMore) {
                HStack(spacing: 4) {
                    Text("profile.seeMore.title")
                        .typography(.subtitle2)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .accessibilityHidden(true)
                }
                .foregroundStyle(Color.brandPurple500)
                // Taller than the line, so the header stays compact but the link is still easy to hit.
                .contentShape(.rect.inset(by: -10))
            }
            .buttonStyle(.plain)
        }
    }
}
