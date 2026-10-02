import SwiftUI

/// The "Avaliação" alert shown over the map once the user has left a place they checked in at.
struct RatingPromptView: View {
    let placeName: String
    let selectedTag: ImpressionTag?
    let isSubmitting: Bool
    let errorMessage: String?
    let onSelect: (ImpressionTag) -> Void
    let onSubmit: () -> Void
    let onDismiss: () -> Void

    // Visual order from the design: orange grin (happy), pink smile (delighted), green sick face.
    private static let topRow: [ImpressionTag] = [.happy, .delighted, .nauseated]
    private static let bottomRow: [ImpressionTag] = [.sad, .sleepy]

    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .contentShape(.rect)

            alert
        }
    }

    private var alert: some View {
        VStack(spacing: 10) {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("ratingPrompt.title")
                        .font(.headline)

                    Text(message)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 0) {
                    emotionRow(Self.topRow, spacing: 5)
                    emotionRow(Self.bottomRow, spacing: 24)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color("AuthError"))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 24)

            buttons
        }
        .padding(14)
        .frame(width: 300)
        .glassEffect(.regular, in: .rect(cornerRadius: 34))
    }

    private var message: AttributedString {
        var name = AttributedString(placeName)
        name.inlinePresentationIntent = .stronglyEmphasized
        return AttributedString(localized: "ratingPrompt.message.prefix")
            + name
            + AttributedString(localized: "ratingPrompt.message.suffix")
    }

    private func emotionRow(_ tags: [ImpressionTag], spacing: CGFloat) -> some View {
        HStack(spacing: spacing) {
            ForEach(tags, id: \.self) { tag in
                RatingPromptEmotionButton(tag: tag, isSelected: tag == selectedTag) {
                    onSelect(tag)
                }
            }
        }
    }

    private var buttons: some View {
        HStack(spacing: 16) {
            Button(action: onDismiss) {
                Text("ratingPrompt.dismissButton.title")
                    .frame(maxWidth: .infinity)
            }
            .tint(.primary)
            .buttonStyle(.glass)
            .disabled(isSubmitting)

            Button(action: onSubmit) {
                Group {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text("ratingPrompt.submitButton.title")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(Color("RatingPromptPrimary"))
            .disabled(selectedTag == nil || isSubmitting)
        }
        .controlSize(.large)
        .buttonBorderShape(.capsule)
        .frame(maxWidth: .infinity)
    }
}

private struct RatingPromptPreview: View {
    @State var selectedTag: ImpressionTag?

    var body: some View {
        RatingPromptView(
            placeName: "Jardim Botânico",
            selectedTag: selectedTag,
            isSubmitting: false,
            errorMessage: nil,
            onSelect: { selectedTag = $0 },
            onSubmit: {},
            onDismiss: {}
        )
    }
}

#Preview("Nothing selected") {
    RatingPromptPreview()
}

#Preview("Happy") {
    RatingPromptPreview(selectedTag: .happy)
}

#Preview("Delighted") {
    RatingPromptPreview(selectedTag: .delighted)
}

#Preview("Nauseated") {
    RatingPromptPreview(selectedTag: .nauseated)
}
