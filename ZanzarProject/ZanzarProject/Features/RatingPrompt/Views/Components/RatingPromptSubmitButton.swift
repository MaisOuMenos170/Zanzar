import SwiftUI

/// "Enviar" at the bottom of the rating sheet: gray until a face is chosen, indigo after (Figma "Avaliação").
struct RatingPromptSubmitButton: View {
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void

    private var fill: Color {
        isEnabled || isLoading ? .brandPurple500 : .brandNeutral200
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Text("ratingPrompt.submitButton.title")
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .transition(.opacity)
                }
            }
            .scaledFont(size: 14, weight: .semibold)
            .tracking(0.1)
            .foregroundStyle(Color.brandNeutral50)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(fill, in: .rect(cornerRadius: 30))
            .contentShape(.rect(cornerRadius: 30))
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!isEnabled || isLoading)
        .motion(Motion.suave, value: isEnabled)
        .motion(Motion.suave, value: isLoading)
    }
}

#Preview {
    VStack {
        RatingPromptSubmitButton(isEnabled: false, isLoading: false) {}
        RatingPromptSubmitButton(isEnabled: true, isLoading: false) {}
        RatingPromptSubmitButton(isEnabled: true, isLoading: true) {}
    }
    .padding()
}
