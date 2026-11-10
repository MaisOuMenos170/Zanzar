import SwiftUI

/// Links to the places the user suggested and where each one stands.
struct ProfileSuggestionsSection: View {
    let onOpenMySuggestions: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("profile.suggestionsSection.title")
                .font(.title3.weight(.semibold))
            Button(action: onOpenMySuggestions) {
                HStack {
                    Label("profile.suggestionsSection.mySuggestions.title", systemImage: "plus.bubble")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(14)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 14))
        }
    }
}
