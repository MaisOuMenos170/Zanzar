import SwiftUI

/// One thing to say, with the Lero face that fits it and a button to close: the answer after sending, or why the
/// place cannot be sent.
struct ShareMessageView: View {
    let face: String
    let title: Text
    let message: Text
    var celebrates = false
    let onClose: () -> Void

    @State private var isShown = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            VStack(spacing: 12) {
                Image(face)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 112, height: 112)
                    .accessibilityHidden(true)
                    .popIn(isShown)

                title
                    .scaledFont(size: 22, weight: .bold, design: .rounded)
                    .foregroundStyle(Color.brandSheetTitle)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                    .entrance(isShown, order: 1)

                message
                    .scaledFont(size: 14)
                    .tracking(0.25)
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .entrance(isShown, order: 2)
            }
            .padding(.horizontal, 32)

            Spacer(minLength: 24)

            PlaceSuggestionSubmitButton(titleKey: "placeShare.closeButton.title", isLoading: false, action: onClose)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
        }
        .haptic(celebrates ? .sucesso : .alerta, trigger: isShown)
        .onAppear {
            isShown = true
            AccessibilityNotification.ScreenChanged().post()
        }
    }
}

#Preview {
    ShareMessageView(
        face: "CarinhaFeliz",
        title: Text("Sugestão enviada!"),
        message: Text("Seu pedido está em análise pela moderação."),
        celebrates: true,
        onClose: {}
    )
}
