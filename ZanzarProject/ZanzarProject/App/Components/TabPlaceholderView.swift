import SwiftUI

struct TabPlaceholderView: View {
    let tab: MainTab

    var body: some View {
        Color(.systemBackground)
            .overlay {
                Text(LocalizedStringKey(tab.titleKey))
                    .foregroundStyle(.secondary)
            }
            .ignoresSafeArea()
    }
}

#Preview {
    TabPlaceholderView(tab: .checkIn)
}
