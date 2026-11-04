import SwiftUI

private struct PlaceSuggestionOutcomeAlert: ViewModifier {
    @Binding var isPresented: Bool
    let outcome: PlaceSuggestionOutcome?

    func body(content: Content) -> some View {
        content.alert(title, isPresented: $isPresented, presenting: outcome) { _ in
            Button("placeSuggestion.alert.confirm") {}
        } message: { outcome in
            switch outcome {
            case .success:
                Text("placeSuggestion.successAlert.message")
            case .failure(let message):
                Text(message)
            }
        }
    }

    private var title: LocalizedStringKey {
        switch outcome {
        case .failure:
            "placeSuggestion.failureAlert.title"
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
