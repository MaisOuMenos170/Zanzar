import SwiftUI

/// "Enviar sugestão": the indigo pill at the bottom of the sheet (Figma nodes 1998:4951 and 1998:4866).
struct PlaceSuggestionSubmitButton: View {
    let titleKey: LocalizedStringKey
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(titleKey)
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .font(.system(size: 14, weight: .semibold))
            .tracking(0.1)
            .foregroundStyle(Color.brandNeutral50)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.brandPurple500, in: .rect(cornerRadius: 30))
            .contentShape(.rect(cornerRadius: 30))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

#Preview {
    VStack {
        PlaceSuggestionSubmitButton(titleKey: "placeSuggestion.submitButton.title", isLoading: false) {}
        PlaceSuggestionSubmitButton(titleKey: "placeSuggestion.submitButton.title", isLoading: true) {}
    }
    .padding()
}
