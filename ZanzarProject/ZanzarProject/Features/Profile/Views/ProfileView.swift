import SwiftUI
import TipKit

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel(checkInsLimit: ProfileViewModel.passportLimit)
    @State private var blockedProfiles = BlockedProfilesViewModel()
    @State private var section = ProfileSection.passport
    @Environment(AuthSession.self) private var authSession
    @Environment(AppCoordinator.self) private var coordinator

    // Tips
    private let editAvatarTip = ProfileEditAvatarTip()
    private let settingsTip = ProfileSettingsTip()

    /// How many of the loaded check-ins show as cards on the passport.
    private let recentCheckInsCount = 4
    /// How many seals show on the passport.
    private let sealsPreviewCount = 8

    var body: some View {
        content
            .background(Color.profileBackground)
            .navigationTitle(viewModel.profile?.summary.name ?? L10n.string("mainTab.profileTab.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(viewModel.profile?.summary.name ?? L10n.string("mainTab.profileTab.title"))
                        .typography(.headline5)
                        .foregroundStyle(Color.black)
                        .lineLimit(1)
                        .accessibilityAddTraits(.isHeader)
                }
                if viewModel.profile != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        editMenu
                    }
                }
            }
            .alert("profile.signOutConfirmation.title", isPresented: $viewModel.showsSignOutConfirmation) {
                Button("profile.signOutConfirmation.confirmButton.title", role: .destructive) {
                    Task { await viewModel.signOut(using: authSession, coordinator: coordinator) }
                }
                Button("profile.signOutConfirmation.cancelButton.title", role: .cancel) {}
            } message: {
                Text("profile.signOutConfirmation.message")
            }
            .alert("profile.signOutAlert.title", isPresented: $viewModel.signOutFailed) {
                Button("profile.signOutAlert.dismissButton.title", role: .cancel) {
                    viewModel.signOutFailed = false
                }
            }
            .alert("profile.deleteAccount.confirmation.title", isPresented: $viewModel.showsDeleteAccountConfirmation) {
                Button("profile.deleteAccount.confirmation.cancelButton.title", role: .cancel) {}
                Button("profile.deleteAccount.confirmation.confirmButton.title", role: .destructive) {
                    Task { await viewModel.deleteAccount(using: authSession, coordinator: coordinator) }
                }
            } message: {
                Text("profile.deleteAccount.confirmation.message")
            }
            .alert("profile.deleteAccount.errorAlert.title", isPresented: $viewModel.deleteAccountFailed) {
                Button("profile.signOutAlert.dismissButton.title", role: .cancel) {}
            }
            .alert("profile.editName.title", isPresented: $viewModel.showsEditName) {
                TextField("profile.editName.placeholder", text: $viewModel.draftName)
                    .textInputAutocapitalization(.words)
                Button("profile.editName.cancelButton.title", role: .cancel) {}
                Button("profile.editName.saveButton.title") {
                    Task { await viewModel.saveName() }
                }
            }
            .alert("profile.editName.errorAlert.title", isPresented: $viewModel.editNameFailed) {
                Button("profile.signOutAlert.dismissButton.title", role: .cancel) {}
            }
            // Restarts when a pushed screen is popped; a check-in made there shows up here (see `markStale`).
            .task(id: coordinator.path.isEmpty) {
                guard coordinator.path.isEmpty else { return }
                await viewModel.load()
                await blockedProfiles.load()
            }
            // A check-in makes the loaded profile outdated; the load above then skips its freshness window.
            .onReceive(NotificationCenter.default.publisher(for: AppNotification.checkInDidSucceed)) { _ in
                viewModel.markStale()
            }
            // An itinerary being activated or abandoned changes the profile stats; refresh so the count updates.
            .onReceive(NotificationCenter.default.publisher(for: AppNotification.activeItineraryDidChange)) { _ in
                viewModel.markStale()
            }
    }

    private var editMenu: some View {
        Menu {
            Button("profile.menu.editName") {
                viewModel.beginEditingName()
            }
            Button("profile.menu.editAvatar") {
                coordinator.push(.avatarEdit)
            }
        } label: {
            Label("profile.menu.accessibilityLabel", systemImage: "pencil")
        }
        .popoverTip(editAvatarTip, arrowEdge: .top)
    }

    @ViewBuilder
    private var content: some View {
        if let profile = viewModel.profile {
            ScrollView {
                VStack(spacing: 24) {
                    ProfileHeaderView()

                    ProfileSegmentedControl(selection: $section)
                        .popoverTip(settingsTip, arrowEdge: .top)

                    switch section {
                    case .passport:
                        passport(profile)
                    case .settings:
                        ProfileSettingsView(
                            blockedCount: blockedProfiles.hasLoaded ? blockedProfiles.blockedUsers.count : nil,
                            onSignOut: {
                                viewModel.showsSignOutConfirmation = true
                                ProfileSettingsTip.hasVisitedProfile = true
                            },
                            onDeleteAccount: { viewModel.showsDeleteAccountConfirmation = true }
                        )
                    }
                }
                .padding(16)
            }
            .refreshable { await viewModel.load(force: true) }
            .motion(Motion.suave, value: section)
        } else if let errorMessage = viewModel.errorMessage {
            ContentUnavailableView {
                Label("profile.errorState.title", systemImage: "exclamationmark.triangle")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("profile.errorState.retryButton.title") {
                    Task { await viewModel.load(force: true) }
                }
                .disabled(viewModel.isLoading)
            }
        } else {
            ProgressView("profile.loadingIndicator.title")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func passport(_ profile: Profile) -> some View {
        VStack(alignment: .leading, spacing: 32) {
            ProfileStatsView(summary: profile.summary)
            ProfileSealsSection(
                categories: earnedSealCategories(in: profile),
                onSeeMore: { coordinator.push(.allSeals) }
            )
            ProfileRecentCheckInsSection(
                checkIns: Array(profile.recentCheckIns.prefix(recentCheckInsCount)),
                onSeeMore: { coordinator.push(.allCheckIns) }
            )
            ProfilePhotosSection(onSeeMore: { coordinator.push(.myPhotos) })
            ProfileSuggestionsSection(onOpenMySuggestions: { coordinator.push(.mySuggestions) })
        }
    }

    /// The kinds of seal the user has, most recent first, one of each.
    private func earnedSealCategories(in profile: Profile) -> [ZanzarPlaceCategory] {
        var seen: Set<ZanzarPlaceCategory> = []
        return profile.recentCheckIns
            .compactMap(\.sealCategory)
            .filter { seen.insert($0).inserted }
            .prefix(sealsPreviewCount)
            .map { $0 }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ProfileView()
    }
    .environment(AuthSession())
    .environment(AppCoordinator())
}
#endif
