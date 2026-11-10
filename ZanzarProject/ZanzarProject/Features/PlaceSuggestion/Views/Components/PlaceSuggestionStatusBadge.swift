import SwiftUI

/// "In review", "Added" or "Not approved".
struct PlaceSuggestionStatusBadge: View {
    let status: PlaceSuggestionStatus

    var body: some View {
        Label(titleKey, systemImage: symbol)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(tint)
            .background(tint.opacity(0.12), in: .capsule)
    }

    private var titleKey: LocalizedStringKey {
        switch status {
        case .pending, .needsReview: "placeSuggestion.status.underReview"
        case .approved: "placeSuggestion.status.added"
        case .rejected: "placeSuggestion.status.notApproved"
        }
    }

    private var symbol: String {
        switch status {
        case .pending, .needsReview: "hourglass"
        case .approved: "checkmark.circle.fill"
        case .rejected: "xmark.circle"
        }
    }

    private var tint: Color {
        switch status {
        case .pending, .needsReview: .orange
        case .approved: .green
        case .rejected: .red
        }
    }
}
