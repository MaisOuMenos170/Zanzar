import SwiftUI

struct AvatarEditorView: View {
    @State private var viewModel = AvatarEditorViewModel()
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(OnboardingGate.self) private var onboarding

    var body: some View {
        VStack(spacing: 16) {
            preview

            AvatarCategoryTabBar(selection: $viewModel.selectedTab)

            AvatarOptionGrid(
                tab: viewModel.selectedTab,
                selectedValue: viewModel.selectedValue
            ) { value in
                viewModel.select(value)
            }

            if let saveError = viewModel.saveError {
                ErrorBanner(message: saveError)
            }

            Button("avatarEditor.saveButton.title") {
                Task {
                    if await viewModel.save() {
                        coordinator.push(.passportIntro(avatar: viewModel.avatar, username: onboarding.username))
                    }
                }
            }
            .buttonStyle(AuthPrimaryButtonStyle())
            .disabled(viewModel.isSaving)
            .overlay {
                if viewModel.isSaving {
                    ProgressView()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(Color.brandBlue50.ignoresSafeArea())
        .navigationTitle(Text(LocalizedStringKey(viewModel.selectedTab.titleKey)))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .task {
            await viewModel.load()
        }
    }

    private var preview: some View {
        AvatarPortraitView(
            avatar: viewModel.avatar,
            fallbackBackground: Color.avatarBackdrop
        )
        .frame(width: 210, height: 210)
        .overlay(alignment: .bottomTrailing) {
            AvatarBackgroundPicker(color: $viewModel.backgroundColor)
                .padding(.trailing, 18)
        }
    }
}

#Preview {
    NavigationStack {
        AvatarEditorView()
            .environment(AppCoordinator())
            .environment(OnboardingGate())
    }
}
