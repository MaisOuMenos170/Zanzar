import SwiftUI
import UIKit
import UserNotifications

struct ContentView: View {
    @State private var coordinator = AppCoordinator()
    @State private var authSession = AuthSession()
    @State private var toastManager = ToastManager()
    @State private var onboarding = OnboardingGate()
    @State private var showsSessionExpiredAlert = false
    @State private var pushTokenManager = PushTokenManager.shared

    var body: some View {
        Group {
            if showsMainApp {
                MainTabView()
                    .transition(.opacity)
            } else {
                NavigationStack(path: $coordinator.path) {
                    WelcomeView()
                        .navigationDestination(for: Route.self) { coordinator.view(for: $0) }
                }
                .transition(.opacity)
            }
        }
        .motion(Motion.assentar, value: showsMainApp)
        .haptic(.sucesso, trigger: showsMainApp, when: { _, isShown in isShown })
        .onChange(of: authSession.isAuthenticated) { _, isAuthenticated in
            // While onboarding the coordinator already points at the avatar editor.
            guard !onboarding.isActive else { return }
            coordinator.popToRoot()
            if !isAuthenticated {
                pushTokenManager.forgetSentToken()
                // What the app remembers about this account's reviews and pending rating is not the next account's.
                UserDefaultsUserPhotoStatusStore().clear()
                UserDefaultsPlaceSuggestionStatusStore().clear()
                UserDefaultsPendingRatingStore().clear()
                // Reminders for places opening belong to the account that asked for them.
                Task { await UserNotificationOpeningReminderScheduler().cancelAll() }
                Task { await ProximityAlertCoordinator.shared.stop() }
            }
        }
        // Once the main app is on screen (a fresh sign-in after onboarding, or a session restored at launch):
        // register for remote notifications and send the device token to the backend. This cannot hang off
        // `isAuthenticated` above, which flips while the onboarding gate is still active and returns early.
        .task(id: showsMainApp) {
            guard showsMainApp else { return }
            await registerForRemoteNotifications()
            await pushTokenManager.sendIfNeeded()
        }
        .alert("auth.sessionExpired.title", isPresented: $showsSessionExpiredAlert) {
            Button("auth.sessionExpired.dismissButton.title", role: .cancel) {}
        } message: {
            Text("auth.sessionExpired.message")
        }
        .onReceive(NotificationCenter.default.publisher(for: AppNotification.sessionExpired)) { _ in
            handleSessionExpired()
        }
        // A shared place link, as `lero://place/<id>` or as the https link (Universal Link).
        .onOpenURL(perform: openPlaceLink)
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            if let url = activity.webpageURL { openPlaceLink(url) }
        }
        .overlay {
            ToastOverlay()
        }
        .preferredColorScheme(.light)
        .environment(coordinator)
        .environment(authSession)
        .environment(toastManager)
        .environment(onboarding)
    }
}

private extension ContentView {
    /// The main screen opens the place once it is on screen, which may be after signing in.
    func openPlaceLink(_ url: URL) {
        guard let placeID = PlaceLink.placeID(from: url) else { return }
        ProximityAlertRouter.shared.open(placeID: placeID)
    }

    var showsMainApp: Bool {
        authSession.isAuthenticated && !onboarding.isActive
    }

    func registerForRemoteNotifications() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        // Never asks: the onboarding step and the proximity explainer do that, with their own words. A user who
        // picked "Not now" must not get the system prompt at the next launch.
        guard settings.authorizationStatus != .notDetermined else { return }
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
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
