import SwiftUI

@main struct MyApp: App {
    init() {
        AppLanguageSettings.applyPreferredLanguageOnLaunch()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, AppLanguageSettings.current.locale)
        }
    }
}
