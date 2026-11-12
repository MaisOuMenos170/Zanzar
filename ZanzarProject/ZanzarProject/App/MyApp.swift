import SwiftUI
import UIKit

@main struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        AppLanguageSettings.applyPreferredLanguageOnLaunch()
        ProximityAlertCoordinator.launch()
        // System alerts are UIKit under the hood and take their button color from here, not from SwiftUI's `.tint`.
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor =
            UIColor(Color.brandPurple500)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, AppLanguageSettings.current.locale)
        }
    }
}
