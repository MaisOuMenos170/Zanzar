import SwiftUI

struct BackendProbeErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.callout)
            .foregroundStyle(.white)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.red.gradient, in: .rect(cornerRadius: 12))
            .accessibilityLabel(message)
    }
}
