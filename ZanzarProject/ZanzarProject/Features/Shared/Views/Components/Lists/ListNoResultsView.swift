import SwiftUI

struct ListNoResultsView: View {
    enum Kind {
        case empty(title: LocalizedStringKey, message: LocalizedStringKey)
        case notFound(query: String, message: LocalizedStringKey)
        case custom(title: LocalizedStringKey, message: LocalizedStringKey)
        case filtered
    }

    /// A button under the text, for a way forward the screen itself offers.
    struct Action {
        let title: LocalizedStringKey
        let perform: () -> Void
    }

    let kind: Kind
    var offersPlaceSuggestion = false
    var action: Action?

    @Environment(\.presentSheet) private var presentSheet

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

    init(kind: Kind, offersPlaceSuggestion: Bool = false, action: Action? = nil) {
        self.kind = kind
        self.offersPlaceSuggestion = offersPlaceSuggestion
        self.action = action
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                switch kind {
                case .empty(let title, let message):
                    text(title: Text(title), message: Text(message))
                case .notFound(let query, let message):
                    text(title: Text("list.noResults.title \(query)"), message: Text(message))
                case .custom(let title, let message):
                    text(title: Text(title), message: Text(message))
                case .filtered:
                    text(title: Text("list.noResults.filterTitle"), message: Text("list.noResults.filterMessage"))
                }
            }
            .foregroundStyle(Color.black)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)

            if offersPlaceSuggestion, !isFiltered, let presentSheet {
                pillButton("list.noResults.suggestButton") { presentSheet(.suggestPlace) }
            }

            if let action {
                pillButton(action.title, perform: action.perform)
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

    private func pillButton(_ title: LocalizedStringKey, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            Text(title)
                .typography(.subtitle2)
                .foregroundStyle(Color.white)
                .padding(16)
                .background(Color.brandPurple500, in: .rect(cornerRadius: 30))
                .contentShape(.rect(cornerRadius: 30))
        }
        .buttonStyle(.plain)
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
