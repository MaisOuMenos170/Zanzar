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

    @State private var isPasswordVisible = false
    @FocusState private var isSecureFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(labelKey)
                .font(.subheadline)
                .tracking(0.25)
                .foregroundStyle(.primary)

            if let errorMessageKey {
                Text(LocalizedStringKey(errorMessageKey))
                    .font(.caption)
                    .foregroundStyle(Color("AuthError"))
            }

            field
                .font(.body)
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
            HStack(spacing: 8) {
                Group {
                    if isPasswordVisible {
                        TextField(placeholderKey, text: $text, prompt: prompt)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        SecureField(placeholderKey, text: $text, prompt: prompt)
                    }
                }
                .textContentType(textContentType)
                .submitLabel(submitLabel)
                .focused($isSecureFieldFocused)

                Button {
                    // Swapping SecureField and TextField drops the focus, so hand it back to keep the keyboard open.
                    let wasFocused = isSecureFieldFocused
                    isPasswordVisible.toggle()
                    if wasFocused {
                        Task { isSecureFieldFocused = true }
                    }
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 25, minHeight: 25)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isPasswordVisible ? "authFormField.hidePassword" : "authFormField.showPassword")
            }
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
