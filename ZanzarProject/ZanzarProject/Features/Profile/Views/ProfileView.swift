import SwiftUI
import TipKit

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel(checkInsLimit: ProfileViewModel.passportLimit)
    @State private var blockedProfiles = BlockedProfilesViewModel()
    @State private var photos = MyPhotosViewModel()
    @State private var suggestions = MySuggestionsViewModel()
    @State private var section = ProfileSection.passport
    /// Turns on a moment after the delete-account alert appears, so the button is not tapped by reflex.
    @State private var canConfirmDeleteAccount = false
    @Environment(AuthSession.self) private var authSession
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.presentSheet) private var presentSheet

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
            // In the alerts, cancel is the filled button (the default action) and the destructive one is red text on
            // gray, as in the Figma. Cancel keeps its `.cancel` role: without one the system adds its own extra
            // "Cancelar" button, and the system always puts the cancel button last.
            .alert("profile.signOutConfirmation.title", isPresented: $viewModel.showsSignOutConfirmation) {
                Button("profile.signOutConfirmation.confirmButton.title", role: .destructive) {
                    Task { await viewModel.signOut(using: authSession, coordinator: coordinator) }
                }
                Button("profile.signOutConfirmation.cancelButton.title", role: .cancel) {}
                    .keyboardShortcut(.defaultAction)
            } message: {
                Text("profile.signOutConfirmation.message")
            }
            .alert("profile.signOutAlert.title", isPresented: $viewModel.signOutFailed) {
                Button("profile.signOutAlert.dismissButton.title", role: .cancel) {
                    viewModel.signOutFailed = false
                }
            }
            .alert("profile.deleteAccount.confirmation.title", isPresented: $viewModel.showsDeleteAccountConfirmation) {
                Button("profile.deleteAccount.confirmation.confirmButton.title", role: .destructive) {
                    Task { await viewModel.deleteAccount(using: authSession, coordinator: coordinator) }
                }
                .disabled(!canConfirmDeleteAccount)
                Button("profile.deleteAccount.confirmation.cancelButton.title", role: .cancel) {}
                    .keyboardShortcut(.defaultAction)
            } message: {
                Text("profile.deleteAccount.confirmation.message")
            }
            .task(id: viewModel.showsDeleteAccountConfirmation) {
                canConfirmDeleteAccount = false
                guard viewModel.showsDeleteAccountConfirmation else { return }
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                canConfirmDeleteAccount = true
            }
            .alert("profile.deleteAccount.errorAlert.title", isPresented: $viewModel.deleteAccountFailed) {
                Button("profile.signOutAlert.dismissButton.title", role: .cancel) {}
            }
            // Restarts when a pushed screen is popped; a check-in made there shows up here (see `markStale`).
            .task(id: coordinator.path.isEmpty) {
                guard coordinator.path.isEmpty else { return }
                await viewModel.load()
                async let blocked: Void = blockedProfiles.load()
                async let photosLoad: Void = photos.load()
                async let suggestionsLoad: Void = suggestions.load()
                _ = await (blocked, photosLoad, suggestionsLoad)
            }
            // A check-in makes the loaded profile outdated; the load above then skips its freshness window.
            .onReceive(NotificationCenter.default.publisher(for: AppNotification.checkInDidSucceed)) { _ in
                viewModel.markStale()
            }
            // The name was changed in the card drawn by the tab bar's root.
            .onReceive(NotificationCenter.default.publisher(for: AppNotification.profileNameDidChange)) { _ in
                Task { await viewModel.load(force: true) }
            }
            // An itinerary being activated or abandoned changes the profile stats; refresh so the count updates.
            .onReceive(NotificationCenter.default.publisher(for: AppNotification.activeItineraryDidChange)) { _ in
                viewModel.markStale()
            }
    }

    private var editMenu: some View {
        Menu {
            Button("profile.menu.editName") {
                presentSheet?(.editName(currentName: viewModel.profile?.summary.name ?? ""))
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
                            photosCount: photos.hasLoaded ? photos.photos.count : nil,
                            suggestionsCount: suggestions.hasLoaded ? suggestions.suggestions.count : nil,
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
