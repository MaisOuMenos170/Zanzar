import SwiftUI
import TipKit

struct AvatarEditorView: View {
    @State private var viewModel = AvatarEditorViewModel()
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(OnboardingGate.self) private var onboarding
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private let avatarEditorTip = OnboardingAvatarEditorTip()

    private var previewSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 120 : 210
    }

    var body: some View {
        VStack(spacing: 16) {
            preview
                .popoverTip(avatarEditorTip, arrowEdge: .top)

            AvatarCategoryTabBar(selection: $viewModel.selectedTab)

            AvatarOptionGrid(
                tab: viewModel.selectedTab,
                selectedValue: viewModel.selectedValue
            ) { value in
                viewModel.select(value)
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
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(LocalizedStringKey(viewModel.selectedTab.titleKey))
                    .typography(.subtitle1)
                    .foregroundStyle(Color.titleBrown)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .toast(for: viewModel.saveError)
        .task {
            await viewModel.load()
        }
    }

    private var preview: some View {
        AvatarPortraitView(
            avatar: viewModel.avatar,
            fallbackBackground: Color.avatarBackdrop
        )
        .frame(width: previewSize, height: previewSize)
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
            .environment(ToastManager())
    }
}
