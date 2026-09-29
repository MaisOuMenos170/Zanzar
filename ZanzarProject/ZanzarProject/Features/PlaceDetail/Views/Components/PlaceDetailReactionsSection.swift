import SwiftUI

struct PlaceDetailReactionsSection: View {
    let reactions: [PlaceDetailReaction]
    let canReact: Bool
    let isSubmitting: Bool
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("placeDetail.reactionsSection.title")
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)

            HStack {
                ForEach(reactions) { reaction in
                    PlaceDetailReactionItem(
                        reaction: reaction,
                        isEnabled: canReact && !reaction.isSelected && !isSubmitting,
                        onSelect: { onSelect(reaction.impressionTag) }
                    )
                    if reaction.id != reactions.last?.id {
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }
}

private struct PlaceDetailReactionItem: View {
    let reaction: PlaceDetailReaction
    let isEnabled: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                Image(reaction.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .opacity(reaction.isSelected ? 1 : (isEnabled ? 0.95 : 0.65))

                Text(reaction.count, format: .number)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color("PlaceDetailReactionCountBackground"), in: .capsule)
                    .offset(y: -8)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(
            String(
                format: String(localized: "placeDetail.reactionItem.accessibilityLabel"),
                locale: Locale.current,
                reaction.count
            )
        )
    }
}
