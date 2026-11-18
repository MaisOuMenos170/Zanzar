import SwiftUI

/// The state of a photo: "Em análise", "Publicada" or "Rejeitada".
struct UserPhotoStatusIndicator: View {
    let status: UserPhotoStatus

    var body: some View {
        StatusDotLabel(title: titleKey, color: dotColor)
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
