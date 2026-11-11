import SwiftUI
import UIKit
import UserNotifications

struct ContentView: View {
    @State private var coordinator = AppCoordinator()
    @State private var authSession = AuthSession()
    @State private var toastPresenter = ToastPresenter()
    @State private var onboarding = OnboardingGate()
    @State private var showsSessionExpiredAlert = false
    @State private var pushTokenManager = PushTokenManager.shared

    var body: some View {
        Group {
            if authSession.isAuthenticated && !onboarding.isActive {
                MainTabView()
            } else {
                NavigationStack(path: $coordinator.path) {
                    WelcomeView()
                        .navigationDestination(for: Route.self) { coordinator.view(for: $0) }
                }
            }
        }
        .onChange(of: authSession.isAuthenticated) { _, isAuthenticated in
            // While onboarding the coordinator already points at the avatar editor.
            guard !onboarding.isActive else { return }
            coordinator.popToRoot()
            if isAuthenticated {
                // Register for remote notifications and send the device token to the backend.
                Task {
                    await registerForRemoteNotifications()
                    await pushTokenManager.sendIfNeeded()
                }
            } else {
                Task { await ProximityAlertCoordinator.shared.stop() }
            }
        }
        .alert("auth.sessionExpired.title", isPresented: $showsSessionExpiredAlert) {
            Button("auth.sessionExpired.dismissButton.title", role: .cancel) {}
        } message: {
            Text("auth.sessionExpired.message")
        }
        .onReceive(NotificationCenter.default.publisher(for: AppNotification.sessionExpired)) { _ in
            handleSessionExpired()
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            ToastOverlay()
        }
        .preferredColorScheme(.light)
        .environment(coordinator)
        .environment(authSession)
        .environment(toastPresenter)
        .environment(onboarding)
    }
}

private extension ContentView {
    func registerForRemoteNotifications() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        // Already authorized (including provisionally): just register for the device token.
        guard settings.authorizationStatus == .notDetermined else {
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
            return
        }
        do {
            try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            AppLog.network.warning("Failed to request remote notification authorization")
        }
    }

    func handleSessionExpired() {
        guard authSession.isAuthenticated else { return }
        authSession.handleSessionExpired()
        let hadSheet = coordinator.presentedSheet != nil
        coordinator.dismissSheet()
        coordinator.popToRoot()
        guard hadSheet else {
            showsSessionExpiredAlert = true
            return
        }
        // An alert can't appear while the sheet is still dismissing.
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            showsSessionExpiredAlert = true
        }
    }
}

#Preview {
    ContentView()
}
