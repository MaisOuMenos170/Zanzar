import SwiftUI

struct AvatarCategoryTabButton: View {
    let tab: AvatarEditorTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            icon
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background { background }
                .clipShape(.rect(cornerRadius: 36))
                .shadow(color: .black.opacity(0.03), radius: isSelected ? 2 : 1, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(LocalizedStringKey(tab.titleKey)))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var icon: some View {
        if isSelected {
            Image(tab.iconName)
                .renderingMode(.template)
                .foregroundStyle(.white)
        } else {
            Image(tab.iconName)
        }
    }

    @ViewBuilder
    private var background: some View {
        if isSelected {
            Color.brandCoral500
                .overlay {
                    Stripe(width: 14.9, height: 91, offset: CGSize(width: -8, height: 4))
                    Stripe(width: 6.7, height: 91, offset: CGSize(width: 6, height: -2))
                }
        } else {
            Color.brandNeutral50
        }
    }

    private struct Stripe: View {
        let width: CGFloat
        let height: CGFloat
        let offset: CGSize

        var body: some View {
            Rectangle()
                .fill(Color.brandPink200.opacity(0.18))
                .frame(width: height, height: width)
                .rotationEffect(.degrees(-43.33))
                .offset(offset)
        }
    }
}
