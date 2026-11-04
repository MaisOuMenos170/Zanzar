import SwiftUI

/// Links to the user's photos and to how photos and blocking work.
struct ProfilePhotosSection: View {
    let onOpenMyPhotos: () -> Void
    let onOpenPrivacy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("profile.photosSection.title")
                .font(.title3.weight(.semibold))
            VStack(spacing: 0) {
                row(
                    titleKey: "profile.photosSection.myPhotos.title",
                    systemImage: "photo.on.rectangle",
                    action: onOpenMyPhotos
                )
                Divider()
                row(titleKey: "profile.photosSection.privacy.title", systemImage: "hand.raised", action: onOpenPrivacy)
            }
            .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 14))
        }
    }

    private func row(titleKey: LocalizedStringKey, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(titleKey, systemImage: systemImage)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
