import SwiftUI

/// A short message in a white pill with a thin gray border: a green check for good news, a red cross for bad.
struct ToastView: View {
    let message: String
    var style = ToastStyle.negative

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: style.symbolName)
                .font(.callout.weight(.medium))
                .foregroundStyle(style.tint)
                .accessibilityHidden(true)

            Text(message)
                .typography(.subtitle2)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color.brandNeutral50, in: .rect(cornerRadius: 47))
        .overlay {
            RoundedRectangle(cornerRadius: 47)
                .strokeBorder(Color("PlaceSuggestionOptionBorder"), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(message)
        .accessibilityAddTraits(.isStaticText)
    }
}

#Preview {
    VStack(spacing: 16) {
        ToastView(message: "Mensagem positiva!", style: .positive)
        ToastView(message: "Mensagem negativa", style: .negative)
    }
    .padding(16)
    .background(Color.brandBlue50)
}
