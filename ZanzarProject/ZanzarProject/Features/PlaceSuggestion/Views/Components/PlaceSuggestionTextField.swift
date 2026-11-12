import SwiftUI

/// The "Nome/Endereço*" field of "Sugerir um lugar" (Figma nodes 1998:5047 and 2020:5099): gray while empty,
/// white with an indigo outline once it has text or focus.
struct PlaceSuggestionTextField: View {
    let labelKey: LocalizedStringKey
    let placeholderKey: LocalizedStringKey
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var isRequired = false
    /// Runs the place search; the keyboard's search key and the magnifier at the end of the field both call it.
    var onSearch: (() -> Void)?
    var canSearch = false
    var isSearching = false

    private var isHighlighted: Bool {
        isFocused.wrappedValue || !text.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            label

            HStack(alignment: .top, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    // Drawn by hand: a text field's own prompt stays on one line and is cut off, while the design
                    // wraps the example address onto two lines.
                    if text.isEmpty {
                        Text(placeholderKey)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.brandFieldPlaceholder)
                            .padding(.trailing, 24)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }

                    TextField("", text: $text, axis: .vertical)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.brandNeutral950)
                        .lineLimit(1...4)
                        .submitLabel(.search)
                        .textInputAutocapitalization(.words)
                        .focused(isFocused)
                        .accessibilityLabel(labelKey)
                        .accessibilityHint(placeholderKey)
                }
                // A multi-line field takes Return as a new line; here it means "search".
                .onChange(of: text) { _, newValue in
                    guard newValue.contains("\n") else { return }
                    text = newValue.replacing("\n", with: "")
                    onSearch?()
                }

                if onSearch != nil, canSearch || isSearching {
                    searchButton
                }
            }
            .padding(16)
            // The whole box takes the tap, not just the first line the text field occupies.
            .contentShape(.rect)
            .onTapGesture { isFocused.wrappedValue = true }
            .background(isHighlighted ? Color.brandNeutral50 : Color.brandNeutral100, in: .rect(cornerRadius: 8))
            .overlay {
                if isHighlighted {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.brandPurple400, lineWidth: 1)
                }
            }
        }
    }

    private var searchButton: some View {
        Button {
            onSearch?()
        } label: {
            Group {
                if isSearching {
                    ProgressView()
                } else {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundStyle(Color.brandPurple500)
            .frame(width: 20, height: 20)
            .padding(8)
            .contentShape(.rect)
            .padding(-8)
        }
        .disabled(!canSearch)
        .accessibilityLabel("placeSuggestion.searchButton.label")
    }

    private var label: some View {
        HStack(spacing: 0) {
            Text(labelKey)
            if isRequired {
                Text("*").foregroundStyle(Color.brandErrorRed)
            }
        }
        .font(.system(size: 14))
        .foregroundStyle(.black)
    }
}

#Preview {
    @Previewable @State var empty = ""
    @Previewable @State var filled = "Jardim Botânico, R. Engo. Ostoja Roguski, 350"
    @Previewable @FocusState var focusedA: Bool
    @Previewable @FocusState var focusedB: Bool
    VStack {
        PlaceSuggestionTextField(
            labelKey: "placeSuggestion.placeField.label",
            placeholderKey: "placeSuggestion.placeField.placeholder",
            text: $empty,
            isFocused: $focusedA,
            isRequired: true
        )
        PlaceSuggestionTextField(
            labelKey: "placeSuggestion.placeField.label",
            placeholderKey: "placeSuggestion.placeField.placeholder",
            text: $filled,
            isFocused: $focusedB,
            isRequired: true
        )
    }
    .padding()
}
