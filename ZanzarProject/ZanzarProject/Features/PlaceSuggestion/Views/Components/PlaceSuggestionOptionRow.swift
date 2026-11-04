import SwiftUI

struct PlaceSuggestionOptionRow: View {
    let titleKey: LocalizedStringKey
    let subtitle: String
    var subtitleIsError = false
    var isLoading = false
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "inset.filled.circle" : "circle")
                    .font(.body.weight(.medium))
                    .foregroundStyle(isSelected ? Color("WelcomePrimary") : Color.secondary)

                VStack(alignment: .leading, spacing: 1) {
                    Text(titleKey)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(subtitleIsError ? Color("AuthError") : Color.secondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isLoading {
                    ProgressView()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                isSelected ? Color("PlaceSuggestionOptionSelectedBackground") : Color(.systemBackground),
                in: .rect(cornerRadius: 8)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSelected ? Color("WelcomePrimary") : Color("PlaceSuggestionOptionBorder"),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
            .contentShape(.rect(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    VStack {
        PlaceSuggestionOptionRow(
            titleKey: "placeSuggestion.locationOption.title",
            subtitle: "R. XV de novembro, 1200",
            isSelected: true,
            action: {}
        )
        PlaceSuggestionOptionRow(
            titleKey: "placeSuggestion.otherPlaceOption.title",
            subtitle: "Digite o nome ou endereço",
            isSelected: false,
            action: {}
        )
    }
    .padding()
}
