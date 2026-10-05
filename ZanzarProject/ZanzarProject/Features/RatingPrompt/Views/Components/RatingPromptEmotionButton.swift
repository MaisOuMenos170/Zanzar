import SwiftUI

struct RatingPromptEmotionButton: View {
    let tag: ImpressionTag
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Image(tag.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 62, height: 62)
                .scaleEffect(isSelected ? 1.2 : 1)
                .shadow(
                    color: .black.opacity(isSelected ? 0.25 : 0),
                    radius: isSelected ? 5.7 : 0,
                    y: isSelected ? 7 : 0
                )
                .opacity(isSelected ? 1 : 0.7)
                .frame(width: 80, height: 80)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : .spring(duration: 0.3, bounce: 0.35), value: isSelected)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var accessibilityLabel: LocalizedStringKey {
        switch tag {
        case .delighted: "ratingPrompt.emotion.delighted"
        case .happy: "ratingPrompt.emotion.happy"
        case .nauseated: "ratingPrompt.emotion.nauseated"
        case .sad: "ratingPrompt.emotion.sad"
        case .sleepy: "ratingPrompt.emotion.sleepy"
        }
    }
}

#Preview("Unselected") {
    HStack {
        RatingPromptEmotionButton(tag: .happy, isSelected: false) {}
        RatingPromptEmotionButton(tag: .delighted, isSelected: true) {}
    }
    .padding()
}
