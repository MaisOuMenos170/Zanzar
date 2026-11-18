import SwiftUI

/// A row of a settings card: a title, an optional line under it and something on the trailing side.
struct ProfileSettingsRow<Trailing: View>: View {
    let title: Text
    var subtitle: Text?
    var isDestructive = false
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                title
                    .typography(.subtitle2)
                    .foregroundStyle(isDestructive ? Color.brandErrorRed : Color.brandNeutral950)
                if let subtitle {
                    subtitle
                        .typography(.caption1)
                        .foregroundStyle(isDestructive ? Color.brandErrorRed : Color.brandNeutral600)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 43)
        .contentShape(.rect)
    }
}

extension ProfileSettingsRow where Trailing == EmptyView {
    init(title: Text, subtitle: Text? = nil, isDestructive: Bool = false) {
        self.init(title: title, subtitle: subtitle, isDestructive: isDestructive) { EmptyView() }
    }
}

/// A section of the settings: a title and the card under it.
struct ProfileSettingsSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .typography(.headline6)
                .foregroundStyle(Color.black)
                .accessibilityAddTraits(.isHeader)
            ListCard {
                content
            }
        }
    }
}
