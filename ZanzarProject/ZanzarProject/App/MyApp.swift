import SwiftUI

@main struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        AppLanguageSettings.applyPreferredLanguageOnLaunch()
        ProximityAlertCoordinator.launch()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, AppLanguageSettings.current.locale)
        }
    }
}
