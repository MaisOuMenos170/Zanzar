import SwiftUI

/// The label on a photo a user sent: who sent it (or "a visitor"), whether it came with a check-in,
/// "in review" on the author's own pending photo, and a menu to report it or block its author.
struct UserPhotoAttributionView: View {
    let attribution: UserPhotoAttribution
    @Environment(\.userPhotoActionHandler) private var actionHandler

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 4) {
                if attribution.isVerifiedCheckIn {
                    Image(systemName: "checkmark.seal.fill")
                        .accessibilityLabel(Text("shared.userPhoto.verified.accessibilityLabel"))
                }
                Text(authorText)
                    .lineLimit(1)
                if attribution.isOwn && attribution.status.isUnderReview {
                    Text("shared.userPhoto.underReview")
                        .fontWeight(.semibold)
                }
            }
            .font(.caption2)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.black.opacity(0.55), in: .capsule)

            if !attribution.isOwn, let actionHandler {
                Menu {
                    Button("shared.userPhoto.reportButton.title", systemImage: "flag") {
                        actionHandler(attribution, .report)
                    }
                    Button("shared.userPhoto.blockButton.title", systemImage: "hand.raised", role: .destructive) {
                        actionHandler(attribution, .blockAuthor)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(.black.opacity(0.55), in: .circle)
                        .contentShape(.circle)
                }
                .accessibilityLabel(Text("shared.userPhoto.menu.accessibilityLabel"))
            }
        }
    }

    private var authorText: String {
        if attribution.isOwn {
            return L10n.string("shared.userPhoto.byYou")
        }
        if let name = attribution.authorName {
            return L10n.string("shared.userPhoto.byAuthor", name)
        }
        return L10n.string("shared.userPhoto.byVisitor")
    }
}
