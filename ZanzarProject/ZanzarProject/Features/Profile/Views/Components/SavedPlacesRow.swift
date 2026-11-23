import SwiftUI

/// "Lugares salvos (10) >": the row under the numbers of the profile that opens the list of bookmarked places
/// (Figma "Perfil", node 2684:1923).
struct SavedPlacesRow: View {
    /// `nil` until the list has loaded, so the row does not show a wrong "(0)".
    let count: Int?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text("savedPlaces.title")
                    .typography(.subtitle2)
                    .foregroundStyle(Color.brandNeutral950)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 4) {
                    if let count {
                        Text("savedPlaces.row.count \(count)")
                            .typography(.caption1)
                            .foregroundStyle(Color.brandNeutral600)
                    }
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.brandNeutral950)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.brandNeutral50, in: .rect(cornerRadius: 16))
            .contentShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        SavedPlacesRow(count: 10) {}
        SavedPlacesRow(count: nil) {}
    }
    .padding()
    .background(Color.profileBackground)
}
