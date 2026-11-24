import SwiftUI

/// One of the five faces of the rating sheet, with its label under it (Figma "Avaliação", frame 2020:9478).
/// While one face is chosen the other four fade to half.
struct RatingPromptEmotionButton: View {
    let tag: ImpressionTag
    let isSelected: Bool
    let isDimmed: Bool
    let action: () -> Void

    /// Height of the slot every face sits in, so the labels line up under the tallest one.
    private static let slotHeight: CGFloat = 66.687

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(tag.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: faceSize.width, height: faceSize.height)
                    .frame(height: Self.slotHeight, alignment: .top)
                    .accessibilityHidden(true)

                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.brandNeutral600)
            }
            .opacity(isDimmed ? 0.5 : 1)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Each face is drawn at its own size in the design: "Legal" is the largest.
    private var faceSize: CGSize {
        switch tag {
        case .delighted, .sleepy: CGSize(width: 61.472, height: 58.322)
        case .happy: CGSize(width: 68.327, height: 66.687)
        case .sad: CGSize(width: 62.57, height: 59.252)
        case .nauseated: CGSize(width: 62.696, height: 59.484)
        }
    }

    private var label: LocalizedStringKey {
        switch tag {
        case .delighted: "ratingPrompt.emotion.delighted"
        case .happy: "ratingPrompt.emotion.happy"
        case .nauseated: "ratingPrompt.emotion.nauseated"
        case .sad: "ratingPrompt.emotion.sad"
        case .sleepy: "ratingPrompt.emotion.sleepy"
        }
    }
}

#Preview("Nothing chosen, then one chosen") {
    VStack(spacing: 24) {
        HStack(alignment: .top, spacing: 7.623) {
            ForEach(ImpressionTag.allCases, id: \.self) {
                RatingPromptEmotionButton(tag: $0, isSelected: false, isDimmed: false) {}
            }
        }
        HStack(alignment: .top, spacing: 7.623) {
            ForEach(ImpressionTag.allCases, id: \.self) {
                RatingPromptEmotionButton(tag: $0, isSelected: $0 == .delighted, isDimmed: $0 != .delighted) {}
            }
        }
    }
    .padding()
}
