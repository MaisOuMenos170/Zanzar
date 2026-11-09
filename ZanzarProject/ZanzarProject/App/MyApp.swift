import SwiftUI

@main struct MyApp: App {
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
