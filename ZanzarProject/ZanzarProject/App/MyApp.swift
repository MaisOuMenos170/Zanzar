import SwiftUI
import UIKit
import TipKit

@main struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var tipKitViewModel = TipKitViewModel()

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
                .task {
                    await tipKitViewModel.configure()
                }
        }
    }
}
