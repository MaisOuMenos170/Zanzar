import SwiftUI

/// Read-only summary of the reactions people left on a place. Reactions are given from the
/// rating prompt on the map, never from here.
struct PlaceDetailReactionsSection: View {
    let reactions: [PlaceDetailReaction]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("placeDetail.reactionsSection.title")
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)

            if displayedReactions.isEmpty {
                Text("placeDetail.reactionsSection.emptyMessage")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack {
                    ForEach(displayedReactions) { reaction in
                        PlaceDetailReactionItem(reaction: reaction)
                        if reaction.id != displayedReactions.last?.id {
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
    }

    private var displayedReactions: [PlaceDetailReaction] {
        PlaceDetailReaction.displayed(reactions)
    }
}

private struct PlaceDetailReactionItem: View {
    let reaction: PlaceDetailReaction

    var body: some View {
        VStack(spacing: 0) {
            Image(reaction.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)

            Text(reaction.count, format: .number)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color("PlaceDetailReactionCountBackground"), in: .capsule)
                .offset(y: -8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(reaction.isSelected ? .isSelected : [])
        .accessibilityLabel(
            String(
                format: String(localized: "placeDetail.reactionItem.accessibilityLabel"),
                locale: Locale.current,
                reaction.count
            )
        )
    }
}
