import SwiftUI

struct PlaceDetailReactionsSection: View {
    let reactions: [PlaceDetailReaction]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("placeDetail.reactionsSection.title")
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)

            HStack {
                ForEach(reactions) { reaction in
                    PlaceDetailReactionItem(reaction: reaction)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String(
                format: String(localized: "placeDetail.reactionItem.accessibilityLabel"),
                locale: Locale.current,
                reaction.count
            )
        )
    }
}
