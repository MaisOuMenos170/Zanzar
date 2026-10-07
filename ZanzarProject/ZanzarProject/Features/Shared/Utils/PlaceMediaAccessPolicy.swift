import Foundation
import Network
import Observation

@MainActor
@Observable
final class PlaceMediaAccessPolicy {
    static let shared = PlaceMediaAccessPolicy()

    private(set) var isOnline = true
    private(set) var usesCellular = false
    var allowsCellularImages: Bool {
        get { UserDefaults.standard.bool(forKey: Self.cellularPreferenceKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.cellularPreferenceKey) }
    }

    private static let cellularPreferenceKey = "placeMedia.allowsCellularImages"
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "placeMedia.networkMonitor")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOnline = path.status == .satisfied
                self?.usesCellular = path.usesInterfaceType(.cellular)
            }
        }
        monitor.start(queue: monitorQueue)
    }

    var canLoadRemoteImages: Bool {
        guard isOnline else { return false }
        if usesCellular {
            return allowsCellularImages
        }
        return true
    }

    var needsCellularPermissionPrompt: Bool {
        isOnline && usesCellular && !allowsCellularImages
    }

    #if DEBUG
    /// Overrides network state for unit tests; production code uses `NWPathMonitor`.
    func setNetworkStateForTesting(isOnline: Bool, usesCellular: Bool) {
        self.isOnline = isOnline
        self.usesCellular = usesCellular
    }
    #endif
}
