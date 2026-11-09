import SwiftUI

struct AuthSwitchLink: View {
    let promptKey: LocalizedStringKey
    let actionKey: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(promptKey)
            Button(action: action) {
                Text(actionKey)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.plain)
        }
        .font(.subheadline)
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)
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
