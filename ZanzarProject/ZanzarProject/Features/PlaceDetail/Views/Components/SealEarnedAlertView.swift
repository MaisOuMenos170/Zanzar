import SwiftUI

struct SealEarnedAlertView: View {
    let placeName: String
    let category: ZanzarPlaceCategory
    let onAccept: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .contentShape(.rect)

            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("placeDetail.sealEarnedAlert.title")
                        .font(.headline)

                    Text(message)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                PlaceCategorySealView(category: category, state: .earned, size: 120)

                Button("placeDetail.sealEarnedAlert.acceptButton.title", action: onAccept)
                    .buttonStyle(.glassProminent)
                    .tint(Color("RatingPromptPrimary"))
                    .controlSize(.large)
                    .buttonBorderShape(.capsule)
                    .frame(maxWidth: .infinity)
            }
            .padding(14)
            .frame(width: 300)
            .glassEffect(.regular, in: .rect(cornerRadius: 34))
        }
    }

    private var message: AttributedString {
        var name = AttributedString(placeName)
        name.inlinePresentationIntent = .stronglyEmphasized
        return AttributedString(localized: "placeDetail.sealEarnedAlert.message.prefix")
            + name
            + AttributedString(localized: "placeDetail.sealEarnedAlert.message.suffix")
    }
}

#Preview {
    SealEarnedAlertView(placeName: "Bar do Zé", category: .bar, onAccept: {})
}
