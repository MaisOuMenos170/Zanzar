import SwiftUI

/// One of the user's suggestions in a list card: the place, the date and where the suggestion stands.
struct MySuggestionRow: View {
    let suggestion: MySuggestion

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(suggestion.displayName)
                .typography(.subtitle2)
                .foregroundStyle(Color.black)
                .lineLimit(1)
            HStack(spacing: 8) {
                Text(suggestion.createdAt.formatted(date: .numeric, time: .omitted))
                    .typography(.caption1)
                    .foregroundStyle(Color.brandNeutral600)
                PlaceSuggestionStatusIndicator(status: suggestion.status)
            }
            if let reason = shownReason {
                Text(LocalizedStringKey(reason.messageKey))
                    .typography(.caption1)
                    .foregroundStyle(Color.brandNeutral600)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .accessibilityElement(children: .combine)
    }

    /// Only a refusal, or a hand-typed suggestion the team accepted, has something to explain.
    private var shownReason: PlaceSuggestionDecisionReason? {
        guard let reason = suggestion.decisionReason else { return nil }
        if suggestion.status == .rejected || reason == .acceptedManual { return reason }
        return nil
    }
}
