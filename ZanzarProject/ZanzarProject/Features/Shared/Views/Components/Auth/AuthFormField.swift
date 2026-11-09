import SwiftUI

struct AuthFormField: View {
    let labelKey: LocalizedStringKey
    let placeholderKey: LocalizedStringKey
    @Binding var text: String
    var errorMessageKey: String?
    var isSecure = false
    var textContentType: UITextContentType?
    var keyboardType: UIKeyboardType = .default
    var submitLabel: SubmitLabel = .next

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(labelKey)
                .font(.system(size: 14))
                .tracking(0.25)
                .foregroundStyle(.primary)

            if let errorMessageKey {
                Text(LocalizedStringKey(errorMessageKey))
                    .font(.caption)
                    .foregroundStyle(Color("AuthError"))
            }

            field
                .font(.system(size: 16))
                .padding(16)
                .frame(minHeight: 51, alignment: .leading)
                .background(Color.brandNeutral50, in: .capsule)
                .overlay {
                    if errorMessageKey != nil {
                        Capsule()
                            .stroke(Color("AuthError"), lineWidth: 1)
                    }
                }
        }
    }

    private var prompt: Text {
        Text(placeholderKey).foregroundStyle(Color.brandNeutral300)
    }

    @ViewBuilder
    private var field: some View {
        if isSecure {
            SecureField(placeholderKey, text: $text, prompt: prompt)
                .textContentType(textContentType)
                .submitLabel(submitLabel)
        } else {
            // A single-line field: with a vertical axis the return key would add a line instead of submitting.
            TextField(placeholderKey, text: $text, prompt: prompt)
                .textContentType(textContentType)
                .keyboardType(keyboardType)
                .submitLabel(submitLabel)
                // Names and e-mails are typed as they are: no forced capital letter and no autocorrect.
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }
}
