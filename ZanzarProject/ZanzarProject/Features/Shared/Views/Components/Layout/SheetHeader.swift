import SwiftUI

/// The top of the cards drawn over the app ("Sugerir um lugar", "Editar nome"): a rounded title, the close
/// button and a line of explanation under them.
struct SheetHeader: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.brandSheetTitle)
                    .accessibilityAddTraits(.isHeader)

                Spacer(minLength: 8)

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.brandCloseIcon)
                        .padding(8)
                        .contentShape(.rect)
                        // The tap target is 8pt bigger than the glyph, but the row keeps the Figma height.
                        .padding(-8)
                }
                .accessibilityLabel("placeSuggestion.closeButton.label")
            }
            .padding(.top, 4)
            .padding(.bottom, 8)

            Text(subtitle)
                .font(.system(size: 14))
                .tracking(0.25)
                .foregroundStyle(.black)
        }
    }
}

#Preview {
    SheetHeader(title: "Sugerir um lugar", subtitle: "Conheça um lugar e conte pra gente!", onClose: {})
        .padding()
}
