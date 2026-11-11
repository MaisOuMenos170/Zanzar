import SwiftUI

@main struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var passwordResetLinks = PasswordResetLinkInbox()

    init() {
        AppLanguageSettings.applyPreferredLanguageOnLaunch()
        ProximityAlertCoordinator.launch()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, AppLanguageSettings.current.locale)
                .environment(passwordResetLinks)
                // lero://reset-password?token=…, opened by the bridge page the reset email links to.
                .onOpenURL { url in
                    passwordResetLinks.receive(url)
                }
        }
    }
}
