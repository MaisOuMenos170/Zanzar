import SwiftUI

private struct PlaceSuggestionOutcomeAlert: ViewModifier {
    @Binding var isPresented: Bool
    let outcome: PlaceSuggestionOutcome?

    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: $isPresented, presenting: outcome) { _ in
                // The default action is the filled indigo button of the Figma alert.
                Button("placeSuggestion.alert.confirm") {}
                    .keyboardShortcut(.defaultAction)
            } message: { outcome in
                switch outcome {
                case .success:
                    Text("placeSuggestion.successAlert.message")
                case .published(let placeName):
                    Text(L10n.string("placeSuggestion.publishedAlert.message", placeName))
                case .refused(let reason):
                    Text(LocalizedStringKey(reason.messageKey))
                case .failure(let message):
                    Text(message)
                }
            }
    }

    private var title: LocalizedStringKey {
        switch outcome {
        case .failure:
            "placeSuggestion.failureAlert.title"
        case .published:
            "placeSuggestion.publishedAlert.title"
        case .refused:
            "placeSuggestion.refusedAlert.title"
        case .success, nil:
            "placeSuggestion.successAlert.title"
        }
    }
}

extension View {
    func placeSuggestionOutcomeAlert(isPresented: Binding<Bool>, outcome: PlaceSuggestionOutcome?) -> some View {
        modifier(PlaceSuggestionOutcomeAlert(isPresented: isPresented, outcome: outcome))
    }
}
