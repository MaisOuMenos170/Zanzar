import SwiftUI

struct AuthSwitchLink: View {
    let promptKey: LocalizedStringKey
    let actionKey: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        AdaptiveStack(horizontalAlignment: .center, spacing: 4) {
            Text(promptKey)
                .typography(.body2)
                .multilineTextAlignment(.center)
            Button(action: action) {
                Text(actionKey)
                    .typography(.subtitle2)
                    .multilineTextAlignment(.center)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AuthSwitchLink(
        promptKey: "auth.switch.haveAccount.prompt",
        actionKey: "auth.switch.haveAccount.action"
    ) {}
    .padding()
    .background(Color.brandBlue50)
}
