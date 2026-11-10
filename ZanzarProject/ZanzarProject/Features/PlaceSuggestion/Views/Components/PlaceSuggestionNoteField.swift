import SwiftUI

struct PlaceSuggestionNoteField: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("placeSuggestion.noteField.label")
                .font(.subheadline)
                .foregroundStyle(.primary)

            TextField("placeSuggestion.noteField.placeholder", text: $text, axis: .vertical)
                .font(.body)
                .lineLimit(4...10)
                .focused($isFocused)
                // Return adds a line in a multi-line field, so the keyboard needs its own way out.
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("keyboard.doneButton.title") { isFocused = false }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .frame(minHeight: 102, alignment: .topLeading)
                .background(Color("AuthFieldBackground"), in: .rect(cornerRadius: 8))
        }
    }
}

#Preview {
    PlaceSuggestionNoteField(text: .constant(""))
        .padding()
}
