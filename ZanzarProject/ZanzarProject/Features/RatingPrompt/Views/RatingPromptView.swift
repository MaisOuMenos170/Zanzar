import SwiftUI

/// The "Avalie a experiência" sheet shown over the map once the user has left a place they checked in at
/// (Figma "Avaliação", frame 2020:9478): the place's photo box, five faces to choose from and "Enviar".
struct RatingPromptView: View {
    let placeID: String
    let placeName: String
    let categoryTitleKey: String?
    let selectedTag: ImpressionTag?
    let isSubmitting: Bool
    let errorMessage: String?
    let onSelect: (ImpressionTag) -> Void
    let onSubmit: () -> Void
    let onDismiss: () -> Void

    /// Best to worst, left to right, as in the design.
    private static let faces: [ImpressionTag] = [.delighted, .happy, .sleepy, .sad, .nauseated]

    @State private var showsPhotoUpload = false

    var body: some View {
        PlaceSuggestionSheetCard(onClose: onDismiss) {
            VStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    VStack(spacing: 40) {
                        RatingPromptPhotoCard(categoryTitleKey: categoryTitleKey) {
                            showsPhotoUpload = true
                        }
                        faceRow
                    }
                }

                VStack(spacing: 12) {
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Color.brandErrorRed)
                            .multilineTextAlignment(.center)
                    }

                    RatingPromptSubmitButton(isEnabled: selectedTag != nil, isLoading: isSubmitting, action: onSubmit)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            // The Figma sheet ends 40pt below the button, counting the home indicator area.
            .padding(.bottom, max(0, 40 - ScreenInsets.bottom))
            .sheetCloseButton(hugsContent: true, isDisabled: isSubmitting, action: onDismiss)
        }
        .haptic(.selecao, trigger: selectedTag, when: { _, tag in tag != nil })
        .sheet(isPresented: $showsPhotoUpload) {
            PhotoUploadSheet(placeID: placeID, placeName: placeName, fromCheckIn: true)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("ratingPrompt.title")
                    .scaledFont(size: 22, weight: .bold, design: .rounded)
                    .foregroundStyle(Color.brandSheetTitle)
                    .accessibilityAddTraits(.isHeader)

                Spacer(minLength: 8)
            }
            .padding(.trailing, 44)
            .padding(.top, 4)
            .padding(.bottom, 8)

            Text(message)
                .scaledFont(size: 14)
                .tracking(0.25)
                .foregroundStyle(.black)
        }
        .padding(.horizontal, 8)
    }

    private var faceRow: some View {
        HStack(alignment: .top, spacing: 7.623) {
            ForEach(Self.faces, id: \.self) { tag in
                RatingPromptEmotionButton(
                    tag: tag,
                    isSelected: tag == selectedTag,
                    isDimmed: selectedTag != nil && tag != selectedTag
                ) {
                    onSelect(tag)
                }
                .disabled(isSubmitting)
            }
        }
        .frame(maxWidth: .infinity)
        .motion(Motion.suave, value: selectedTag)
    }

    /// "Como foi sua visita ao **Jardim Botânico**?", with the place's name in semibold.
    private var message: AttributedString {
        var name = AttributedString(placeName)
        name.inlinePresentationIntent = .stronglyEmphasized
        return AttributedString(localized: "ratingPrompt.message.prefix")
            + name
            + AttributedString(localized: "ratingPrompt.message.suffix")
    }
}

private struct RatingPromptPreview: View {
    @State var selectedTag: ImpressionTag?

    var body: some View {
        RatingPromptView(
            placeID: "place-1",
            placeName: "Jardim Botânico",
            categoryTitleKey: "placeDetail.tag.park",
            selectedTag: selectedTag,
            isSubmitting: false,
            errorMessage: nil,
            onSelect: { selectedTag = $0 },
            onSubmit: {},
            onDismiss: {}
        )
    }
}

#Preview("Nothing chosen") {
    RatingPromptPreview()
}

#Preview("Amei!") {
    RatingPromptPreview(selectedTag: .delighted)
}
