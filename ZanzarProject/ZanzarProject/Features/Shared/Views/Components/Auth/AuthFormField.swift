import SwiftUI

struct AuthFormField: View {
    let labelKey: LocalizedStringKey
    let placeholderKey: LocalizedStringKey
    @Binding var text: String
    var errorMessageKey: String?
    var isSecure = false
    var textContentType: UITextContentType?
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(labelKey)
                .font(.subheadline)
                .foregroundStyle(.primary)

            if let errorMessageKey {
                Text(LocalizedStringKey(errorMessageKey))
                    .font(.caption)
                    .foregroundStyle(Color("AuthError"))
            }

            field
                .font(.body)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .frame(minHeight: 45, alignment: .leading)
                .background(Color("AuthFieldBackground"), in: .rect(cornerRadius: 8))
                .overlay {
                    if errorMessageKey != nil {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color("AuthError"), lineWidth: 1)
                    }
                }
        }
    }

    @ViewBuilder
    private var field: some View {
        if isSecure {
            SecureField(placeholderKey, text: $text)
                .textContentType(textContentType)
        } else {
            TextField(placeholderKey, text: $text, axis: .vertical)
                .lineLimit(1...3)
                .textContentType(textContentType)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .sentences)
                .autocorrectionDisabled(keyboardType == .emailAddress)
        }
    }
}
