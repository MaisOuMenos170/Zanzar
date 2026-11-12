import SwiftUI

/// The "Buscar um lugar" bar of the discover screen (Figma "Campo / busca"): a white pill with the search
/// icon, the text and the filter button.
struct DiscoverSearchBar: View {
    @Binding var text: String
    @Binding var filter: PlaceFilter
    var isFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    @ScaledMetric(relativeTo: .body) private var textSize: CGFloat = 16

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: textSize))
                .foregroundStyle(.primary)
                .accessibilityHidden(true)

            TextField(
                "",
                text: $text,
                prompt: Text("discover.search.placeholder").foregroundStyle(Color.brandSearchPlaceholder)
            )
            .font(.system(size: textSize))
            .tracking(0.15)
            .foregroundStyle(.primary)
            .submitLabel(.search)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .focused(isFocused)
            .onSubmit(onSubmit)
            .accessibilityLabel("discover.search.accessibilityLabel")

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: textSize))
                        .foregroundStyle(Color.brandSearchPlaceholder)
                        .padding(8)
                        .contentShape(.rect)
                        .padding(-8)
                }
                .accessibilityLabel("discover.search.clear")
            }

            DiscoverFilterMenu(filter: $filter)
        }
        .padding(.horizontal, 14)
        // 10.5 because a text field is about 3pt taller than its 19pt line, which makes the bar 43pt like Figma's.
        .padding(.vertical, 10.5)
        .background(Color.brandNeutral50, in: .rect(cornerRadius: 24))
        .shadow(color: .black.opacity(0.25), radius: 4, y: 1)
    }
}

#Preview {
    @Previewable @State var text = ""
    @Previewable @State var filter = PlaceFilter()
    @Previewable @FocusState var focused: Bool
    DiscoverSearchBar(text: $text, filter: $filter, isFocused: $focused, onSubmit: {})
        .padding()
        .background(Color.gray.opacity(0.3))
}
