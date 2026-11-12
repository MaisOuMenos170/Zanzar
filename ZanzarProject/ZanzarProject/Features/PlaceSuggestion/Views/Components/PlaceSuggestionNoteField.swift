import SwiftUI

/// The "Descrição" field of "Sugerir um lugar" (Figma node 1998:4949): gray box, at least 98pt tall.
struct PlaceSuggestionNoteField: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("placeSuggestion.noteField.label")
                .font(.system(size: 14))
                .foregroundStyle(.black)

            TextField(
                "",
                text: $text,
                prompt: Text("placeSuggestion.noteField.placeholder").foregroundStyle(Color.brandFieldPlaceholder),
                axis: .vertical
            )
            .font(.system(size: 14))
            .foregroundStyle(Color.brandNeutral950)
            .lineLimit(4...10)
            .focused($isFocused)
            // Return adds a line in a multi-line field, so the keyboard needs its own way out.
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("keyboard.doneButton.title") { isFocused = false }
                }
            }
            .padding(16)
            .frame(minHeight: 98, alignment: .topLeading)
            .background(isFocused ? Color.brandNeutral50 : Color.brandNeutral100, in: .rect(cornerRadius: 8))
            .overlay {
                if isFocused {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.brandPurple400, lineWidth: 1)
                }
            }
        }
    }
}

#Preview {
    PlaceSuggestionNoteField(text: .constant(""))
        .padding()
}
