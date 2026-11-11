import SwiftUI

/// A verification code shown as one box per digit. A single invisible text field sits on top of the boxes, so typing,
/// pasting and the e-mail code suggestion from the keyboard all work like in a normal field.
struct OneTimeCodeField: View {
    let labelKey: LocalizedStringKey
    @Binding var text: String
    var length = 6
    var errorMessageKey: String?

    @FocusState private var isFocused: Bool

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

            ZStack {
                boxes
                    .accessibilityHidden(true)

                // The boxes only display the digits; this field, kept out of the touch path, holds the focus.
                TextField("", text: $text)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($isFocused)
                    .foregroundStyle(.clear)
                    .tint(.clear)
                    .opacity(0.01)
                    .allowsHitTesting(false)
                    .accessibilityLabel("passwordReset.code.field.accessibilityLabel")
                    .accessibilityValue(Text("passwordReset.code.field.accessibilityValue \(text.count) \(length)"))
            }
            .contentShape(.rect)
            .onTapGesture {
                isFocused = true
            }
            .accessibilityAction {
                isFocused = true
            }
        }
    }

    private var boxes: some View {
        HStack(spacing: 8) {
            ForEach(0..<length, id: \.self) { index in
                Text(Self.digit(at: index, in: text))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(Color.brandNeutral50, in: .rect(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor(at: index), lineWidth: 2)
                    }
            }
        }
    }

    private func borderColor(at index: Int) -> Color {
        if errorMessageKey != nil {
            return Color("AuthError")
        }
        let isFilled = index < text.count
        let isActive = isFocused && index == min(text.count, length - 1)
        return isFilled || isActive ? .brandBlue500 : .brandNeutral300
    }

    /// The digit shown in box `index`, or an empty string while that box is still waiting for input.
    static func digit(at index: Int, in code: String) -> String {
        guard index >= 0, index < code.count else { return "" }
        return String(code[code.index(code.startIndex, offsetBy: index)])
    }
}

#Preview {
    @Previewable @State var code = "159"
    OneTimeCodeField(labelKey: "passwordReset.code.field.label", text: $code)
        .padding(16)
        .background(Color.brandBlue50)
}
