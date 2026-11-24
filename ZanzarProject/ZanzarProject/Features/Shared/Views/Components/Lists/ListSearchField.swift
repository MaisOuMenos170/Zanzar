import SwiftUI

struct ListSearchField: View {
    let prompt: LocalizedStringKey
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.brandNeutral700)
                .accessibilityHidden(true)

            TextField(text: $text) {
                Text(prompt).foregroundStyle(Color.brandSearchPlaceholder)
            }
            .typography(.body1)
            .foregroundStyle(Color.brandNeutral950)
            .submitLabel(.search)
            .autocorrectionDisabled()

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Label("listSearchField.clearButton.accessibilityLabel", systemImage: "xmark")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(Color.brandNeutral700)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.brandNeutral50, in: .rect(cornerRadius: 24))
    }
}

#Preview {
    @Previewable @State var text = ""
    ListSearchField(prompt: "Buscar lugar", text: $text)
        .padding()
        .background(Color.profileBackground)
}
