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
    @State private var errorCount = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// A shake and a haptic are for an error that shows up, not one that is rewritten or cleared.
    nonisolated static func isNewError(from old: String?, to new: String?) -> Bool {
        old == nil && new != nil
    }

    private var shakeAmplitude: CGFloat {
        reduceMotion ? 0 : 6
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(labelKey)
                .typography(.body2)
                .foregroundStyle(.primary)

            if let errorMessageKey {
                Text(LocalizedStringKey(errorMessageKey))
                    .font(.caption)
                    .foregroundStyle(Color("AuthError"))
                    .transition(.opacity.combined(with: .offset(y: -4)))
            }

            field
                .typography(.body1)
                .padding(16)
                .frame(minHeight: 51, alignment: .leading)
                .background(Color.brandNeutral50, in: .capsule)
                .overlay {
                    if errorMessageKey != nil {
                        Capsule()
                            .stroke(Color("AuthError"), lineWidth: 1)
                    }
                }
                .keyframeAnimator(initialValue: CGFloat.zero, trigger: errorCount) { content, shift in
                    content.offset(x: shift)
                } keyframes: { _ in
                    KeyframeTrack {
                        CubicKeyframe(shakeAmplitude, duration: 0.05)
                        CubicKeyframe(-shakeAmplitude, duration: 0.09)
                        CubicKeyframe(shakeAmplitude * 0.6, duration: 0.08)
                        CubicKeyframe(0, duration: 0.07)
                    }
                }
        }
        .onChange(of: errorMessageKey) { old, new in
            if Self.isNewError(from: old, to: new) {
                errorCount += 1
            }
        }
        .haptic(.alerta, trigger: errorCount)
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
                        .contentTransition(.symbolEffect(.replace))
                        .motion(Motion.toque, value: isPasswordVisible)
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
