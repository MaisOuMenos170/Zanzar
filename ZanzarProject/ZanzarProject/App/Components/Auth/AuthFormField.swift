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
                Text(errorMessageKey)
                    .font(.caption)
                    .foregroundStyle(Color("AuthError"))
            }

            field
                .padding(.horizontal, 8)
                .frame(height: 45)
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
            TextField(placeholderKey, text: $text)
                .textContentType(textContentType)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .sentences)
                .autocorrectionDisabled(keyboardType == .emailAddress)
        }
    }
}
