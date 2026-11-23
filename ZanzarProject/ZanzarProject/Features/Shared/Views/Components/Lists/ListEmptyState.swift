import SwiftUI

struct ListEmptyState: View {
    let message: LocalizedStringKey

    var body: some View {
        Text(message)
            .typography(.body2)
            .foregroundStyle(Color.brandNeutral600)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.brandNeutral50, in: .rect(cornerRadius: 16))
    }
}

#Preview {
    ListEmptyState(message: "Você não tem check-ins registrados!")
        .padding()
        .background(Color.profileBackground)
}
