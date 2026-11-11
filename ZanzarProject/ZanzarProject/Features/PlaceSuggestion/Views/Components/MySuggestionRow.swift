import SwiftUI

struct MySuggestionRow: View {
    let suggestion: MySuggestion

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var lineLimit: Int? {
        dynamicTypeSize.isAccessibilitySize ? nil : 2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(suggestion.displayName)
                .font(.headline)
                .lineLimit(lineLimit)
            if suggestion.name != nil {
                Text(suggestion.address)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(lineLimit)
            }
            PlaceSuggestionStatusBadge(status: suggestion.status)
            if let reason = shownReason {
                Text(LocalizedStringKey(reason.messageKey))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Text(suggestion.createdAt, format: .dateTime.day().month().year())
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// Only a refusal, or a hand-typed suggestion the team accepted, has something to explain.
    private var shownReason: PlaceSuggestionDecisionReason? {
        guard let reason = suggestion.decisionReason else { return nil }
        if suggestion.status == .rejected || reason == .acceptedManual { return reason }
        return nil
    }
}
