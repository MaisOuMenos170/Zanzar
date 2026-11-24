import SwiftUI

/// A text field of "Sugerir um lugar", for the name and the address (Figma nodes 1998:5047 and
/// 2020:5099): gray while empty, white with an indigo outline once it has text or focus.
struct PlaceSuggestionTextField: View {
    let labelKey: LocalizedStringKey
    let placeholderKey: LocalizedStringKey
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var isRequired = false
    var autocapitalization: TextInputAutocapitalization = .words
    var submitLabel: SubmitLabel = .done
    /// Runs when the user presses Return, e.g. to search without waiting for the pause after typing.
    var onSubmit: (() -> Void)?
    /// When set, tapping the field runs this instead of editing in place: the field only shows the text and opens
    /// the screen where it is typed.
    var onTap: (() -> Void)?
    /// The search field of Figma node 2530:6574 starts with a magnifier and has a darker placeholder.
    var leadingSystemImage: String?
    var placeholderColor: Color = .brandSearchPlaceholder

    @ScaledMetric(relativeTo: .body) private var lineHeight: CGFloat = 17

    private var isHighlighted: Bool {
        isFocused.wrappedValue || !text.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            label

            HStack(alignment: .top, spacing: 10) {
                if let leadingSystemImage {
                    Image(systemName: leadingSystemImage)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.brandNeutral600)
                        // As tall as a line of the 14pt text beside it, so both are centered on the same line.
                        .frame(height: lineHeight)
                        .accessibilityHidden(true)
                }

                ZStack(alignment: .topLeading) {
                    // Drawn by hand: a text field's own prompt stays on one line and is cut off, while the design
                    // wraps the example address onto two lines.
                    if text.isEmpty {
                        Text(placeholderKey)
                            .scaledFont(size: 14)
                            .foregroundStyle(placeholderColor)
                            .padding(.trailing, 24)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }

                    TextField("", text: $text, axis: .vertical)
                        .scaledFont(size: 14)
                        .foregroundStyle(Color.brandNeutral950)
                        .lineLimit(1...4)
                        .submitLabel(submitLabel)
                        .textInputAutocapitalization(autocapitalization)
                        .focused(isFocused)
                        .allowsHitTesting(onTap == nil)
                        .accessibilityLabel(labelKey)
                        .accessibilityHint(placeholderKey)
                }
                // A multi-line field takes Return as a new line; here it ends the typing.
                .onChange(of: text) { _, newValue in
                    guard newValue.contains("\n") else { return }
                    text = newValue.replacing("\n", with: "")
                    isFocused.wrappedValue = false
                    onSubmit?()
                }
            }
            .padding(16)
            // The whole box takes the tap, not just the first line the text field occupies.
            .contentShape(.rect)
            .onTapGesture {
                if let onTap {
                    onTap()
                } else {
                    isFocused.wrappedValue = true
                }
            }
            .background(isHighlighted ? Color.brandNeutral50 : Color.brandNeutral100, in: .rect(cornerRadius: 8))
            .overlay {
                if isHighlighted {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.brandPurple400, lineWidth: 1)
                }
            }
        }
    }

    private var label: some View {
        HStack(spacing: 0) {
            Text(labelKey)
            if isRequired {
                Text("*").foregroundStyle(Color.brandErrorRed)
            }
        }
        .scaledFont(size: 14)
        .foregroundStyle(.black)
    }
}

#Preview {
    @Previewable @State var empty = ""
    @Previewable @State var filled = "Jardim Botânico"
    @Previewable @FocusState var focusedA: Bool
    @Previewable @FocusState var focusedB: Bool
    VStack {
        PlaceSuggestionTextField(
            labelKey: "placeSuggestion.nameField.label",
            placeholderKey: "placeSuggestion.nameField.placeholder",
            text: $empty,
            isFocused: $focusedA,
            isRequired: true
        )
        PlaceSuggestionTextField(
            labelKey: "placeSuggestion.nameField.label",
            placeholderKey: "placeSuggestion.nameField.placeholder",
            text: $filled,
            isFocused: $focusedB,
            isRequired: true
        )
    }
    .padding()
}
