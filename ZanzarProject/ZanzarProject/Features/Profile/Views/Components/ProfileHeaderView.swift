import SwiftUI

struct ProfileHeaderView: View {
    @State private var viewModel = AvatarViewModel()
    @Environment(AppCoordinator.self) private var coordinator

    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 148

    var body: some View {
        Group {
            if let avatar = viewModel.avatar {
                AvatarPortraitView(avatar: avatar)
            } else {
                Circle().fill(Color.brandPurple200)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("profile.avatarButton.accessibilityLabel")
        // Reloads when an avatar edit is popped, so the new face shows up.
        .task(id: coordinator.path.isEmpty) {
            guard coordinator.path.isEmpty else { return }
            await viewModel.load()
        }
    }
}

#Preview {
    ProfileHeaderView()
        .environment(AppCoordinator())
        .padding()
}
