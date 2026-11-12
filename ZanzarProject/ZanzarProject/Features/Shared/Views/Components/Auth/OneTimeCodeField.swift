import SwiftUI

/// A verification code shown as one rounded box per digit, with a thin border. A real text field sits
/// invisibly over the boxes and takes every touch, so the system behaves as in any input: tap to type, press and
/// hold for the standard "Paste" bubble, and the e-mail code suggestion from the keyboard.
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

            HStack(spacing: 8) {
                ForEach(0..<length, id: \.self) { index in
                    Text(Self.digit(at: index, in: text))
                        .font(.title2)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(Color.brandNeutral50, in: .rect(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(borderColor(at: index), lineWidth: 2)
                        }
                }
            }
            .accessibilityHidden(true)
            .overlay {
                // The boxes only display the digits. The text field stays clear, so its caret and selection are
                // not drawn, but it still gets the touches and shows the system edit menu.
                TextField("", text: $text)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($isFocused)
                    .foregroundStyle(.clear)
                    .tint(.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(.rect)
                    .accessibilityLabel("passwordReset.code.field.accessibilityLabel")
                    .accessibilityValue(Text("passwordReset.code.field.accessibilityValue \(text.count) \(length)"))
            }
            .onChange(of: text) {
                let digits = Self.sanitized(text, length: length)
                if digits != text {
                    text = digits
                }
            }
        }
    }

    /// A box changes only once it holds a digit; focus alone leaves the empty boxes as they are.
    private func isFilled(at index: Int) -> Bool {
        index < text.count
    }

    /// Only the border changes between states; the fill is always white.
    /// Border: red on error, purple once filled, the app's light gray while empty.
    private func borderColor(at index: Int) -> Color {
        if errorMessageKey != nil {
            return Color("AuthError")
        }
        return isFilled(at: index) ? .brandPurple400 : Color("PlaceDetailCheckInDoneBorder")
    }

    /// Keeps only the digits, up to `length`, so "123 456" or a whole pasted line still fills the boxes.
    static func sanitized(_ raw: String, length: Int) -> String {
        String(raw.filter { $0.isASCII && $0.isNumber }.prefix(length))
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
