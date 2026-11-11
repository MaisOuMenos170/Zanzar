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
    /// E-mails and usernames are typed as they are; free text such as a place name wants capitals and suggestions.
    var capitalization: TextInputAutocapitalization = .never
    var disablesAutocorrection = true
    /// Bound straight to the text input. A `.focused` placed on this container never fires, because the container
    /// itself cannot take focus, so the parent's focus chain would always read "nothing focused".
    var isFocused: FocusState<Bool>.Binding

    @State private var isPasswordVisible = false

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
                .focused(isFocused)

                Button {
                    // Swapping SecureField and TextField drops the focus, so hand it back to keep the keyboard open.
                    let wasFocused = isFocused.wrappedValue
                    isPasswordVisible.toggle()
                    if wasFocused {
                        Task { isFocused.wrappedValue = true }
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
                .textInputAutocapitalization(capitalization)
                .autocorrectionDisabled(disablesAutocorrection)
                .focused(isFocused)
        }
    }
}
