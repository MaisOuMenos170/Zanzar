import SwiftUI

/// "In review", "Published", "Not approved" or "Removed".
struct UserPhotoStatusBadge: View {
    let status: UserPhotoStatus

    var body: some View {
        Label(titleKey, systemImage: symbol)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(tint)
            .background(tint.opacity(0.12), in: .capsule)
    }

    private var titleKey: LocalizedStringKey {
        switch status {
        case .pending, .needsReview: "userPhotos.status.underReview"
        case .approved: "userPhotos.status.published"
        case .rejected: "userPhotos.status.notApproved"
        case .removed: "userPhotos.status.removed"
        }
    }

    private var symbol: String {
        switch status {
        case .pending, .needsReview: "hourglass"
        case .approved: "checkmark.circle.fill"
        case .rejected: "xmark.circle"
        case .removed: "minus.circle"
        }
    }

    private var tint: Color {
        switch status {
        case .pending, .needsReview: .orange
        case .approved: .green
        case .rejected, .removed: .red
        }
    }
}
