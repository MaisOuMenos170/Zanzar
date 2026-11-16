import SwiftUI

/// A colored dot and the state of a photo: "Em análise", "Publicada" or "Rejeitada".
struct UserPhotoStatusIndicator: View {
    let status: UserPhotoStatus

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
            Text(titleKey)
                .typography(.caption1)
                .foregroundStyle(Color.brandNeutral900)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private var titleKey: LocalizedStringKey {
        switch status {
        case .pending, .needsReview: "userPhotos.status.underReview"
        case .approved: "userPhotos.status.published"
        case .rejected: "userPhotos.status.notApproved"
        case .removed: "userPhotos.status.removed"
        }
    }

    private var dotColor: Color {
        switch status {
        case .pending, .needsReview: .brandYellow500
        case .approved: Color("UICorrect")
        case .rejected, .removed: .brandErrorRed
        }
    }
}
