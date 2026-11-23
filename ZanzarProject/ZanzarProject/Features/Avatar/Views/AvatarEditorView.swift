import SwiftUI
import TipKit

struct AvatarEditorView: View {
    var finishesByPopping = false

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
            // A new tab brings a new grid: the old one fades out and the new one fades in.
            .id(viewModel.selectedTab)
            .transition(.opacity)

            Button {
                Task {
                    if await viewModel.save() {
                        if finishesByPopping {
                            coordinator.pop()
                        } else {
                            coordinator.push(.passportIntro(avatar: viewModel.avatar, username: onboarding.username))
                        }
                    }
                }
            } label: {
                Text("avatarEditor.saveButton.title")
                    .opacity(viewModel.isSaving ? 0 : 1)
            }
            .buttonStyle(AuthPrimaryButtonStyle())
            .disabled(viewModel.isSaving)
            .overlay {
                if viewModel.isSaving {
                    ProgressView()
                        .transition(.opacity)
                }
            }
            .motion(Motion.suave, value: viewModel.isSaving)
        }
        .motion(Motion.suave, value: viewModel.selectedTab)
        .haptic(.selecao, trigger: viewModel.selectedTab)
        .haptic(.selecao, trigger: viewModel.avatar)
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
        // Opened from the profile, the editor takes the whole screen: no tab bar under the save button.
        .toolbar(.hidden, for: .tabBar)
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
