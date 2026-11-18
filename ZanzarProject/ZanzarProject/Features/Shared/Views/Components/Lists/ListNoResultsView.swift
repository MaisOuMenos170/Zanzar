import SwiftUI

/// What a profile list shows when it has nothing to list: because there is nothing yet, because the search found
/// nothing, or because the chip emptied it. A title, a line about it and, where it makes sense, a button to
/// suggest a place.
struct ListNoResultsView: View {
    enum Kind {
        /// The list has nothing at all yet.
        case empty(title: LocalizedStringKey, message: LocalizedStringKey)
        /// The search found nothing. `query` is what the user typed.
        case notFound(query: String, message: LocalizedStringKey)
        /// Only a category chip emptied the list.
        case filtered
    }

    let kind: Kind
    /// Offers "Sugerir lugar" under the message. Not shown when only a chip emptied the list.
    var offersPlaceSuggestion = false

    @Environment(\.presentSheet) private var presentSheet

    /// Picks the right kind: nothing at all, a search with no match, or just the chip.
    init(
        hasItems: Bool,
        query: String,
        emptyTitle: LocalizedStringKey,
        emptyMessage: LocalizedStringKey,
        notFoundMessage: LocalizedStringKey,
        offersPlaceSuggestion: Bool = false
    ) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !hasItems {
            kind = .empty(title: emptyTitle, message: emptyMessage)
        } else if trimmed.isEmpty {
            kind = .filtered
        } else {
            kind = .notFound(query: trimmed, message: notFoundMessage)
        }
        self.offersPlaceSuggestion = offersPlaceSuggestion
    }

    init(kind: Kind, offersPlaceSuggestion: Bool = false) {
        self.kind = kind
        self.offersPlaceSuggestion = offersPlaceSuggestion
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                switch kind {
                case .empty(let title, let message):
                    text(title: Text(title), message: Text(message))
                case .notFound(let query, let message):
                    text(title: Text("list.noResults.title \(query)"), message: Text(message))
                case .filtered:
                    text(title: Text("list.noResults.filterTitle"), message: Text("list.noResults.filterMessage"))
                }
            }
            .foregroundStyle(Color.black)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)

            if offersPlaceSuggestion, !isFiltered, let presentSheet {
                Button { presentSheet(.suggestPlace) } label: {
                    Text("list.noResults.suggestButton")
                        .typography(.subtitle2)
                        .foregroundStyle(Color.white)
                        .padding(16)
                        .background(Color.brandPurple500, in: .rect(cornerRadius: 30))
                        .contentShape(.rect(cornerRadius: 30))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 400)
        .padding(.vertical, 48)
        .accessibilityElement(children: .contain)
    }

    private var isFiltered: Bool {
        if case .filtered = kind { return true }
        return false
    }

    @ViewBuilder
    private func text(title: Text, message: Text) -> some View {
        title
            .typography(.subtitle1)
            .fontWeight(.bold)
            .accessibilityAddTraits(.isHeader)
        message
            .typography(.body2)
    }
}

#Preview {
    ListNoResultsView(
        kind: .notFound(query: "Casa do Sapo", message: "list.noResults.place.message"),
        offersPlaceSuggestion: true
    )
    .background(Color.profileBackground)
    .environment(\.presentSheet, { _ in })
}
