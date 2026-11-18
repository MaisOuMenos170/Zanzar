import SwiftUI

/// The state of a suggestion: "Em análise", "Adicionado" or "Não aprovado".
struct PlaceSuggestionStatusIndicator: View {
    let status: PlaceSuggestionStatus

    var body: some View {
        StatusDotLabel(title: titleKey, color: dotColor)
    }

    private var titleKey: LocalizedStringKey {
        switch status {
        case .pending, .needsReview: "placeSuggestion.status.underReview"
        case .approved: "placeSuggestion.status.added"
        case .rejected: "placeSuggestion.status.notApproved"
        }
    }

    private var dotColor: Color {
        switch status {
        case .pending, .needsReview: .brandYellow500
        case .approved: Color("UICorrect")
        case .rejected: .brandErrorRed
        }
    }
}
