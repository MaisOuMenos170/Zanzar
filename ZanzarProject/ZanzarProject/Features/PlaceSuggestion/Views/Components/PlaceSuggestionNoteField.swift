import SwiftUI

struct PlaceSuggestionNoteField: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("placeSuggestion.noteField.label")
                .font(.subheadline)
                .foregroundStyle(.primary)

            TextField("placeSuggestion.noteField.placeholder", text: $text, axis: .vertical)
                .font(.body)
                .lineLimit(4...10)
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
