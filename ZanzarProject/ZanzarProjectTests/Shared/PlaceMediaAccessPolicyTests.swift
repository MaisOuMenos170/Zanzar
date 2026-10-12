import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("PlaceMediaAccessPolicy", .serialized)
struct PlaceMediaAccessPolicyTests {
    private let policy = PlaceMediaAccessPolicy.shared

    @Test("allows remote images on Wi‑Fi when online")
    func wifiAllowsImages() {
        policy.setNetworkStateForTesting(isOnline: true, usesCellular: false)
        #expect(policy.canLoadRemoteImages)
    }

    @Test("blocks remote images when offline")
    func offlineBlocksImages() {
        policy.setNetworkStateForTesting(isOnline: false, usesCellular: false)
        #expect(!policy.canLoadRemoteImages)
    }

    @Test("blocks cellular images until the user opts in")
    func cellularRequiresOptIn() {
        policy.allowsCellularImages = false
        policy.setNetworkStateForTesting(isOnline: true, usesCellular: true)

        #expect(!policy.canLoadRemoteImages)
        #expect(policy.needsCellularPermissionPrompt)
    }

    @Test("allows cellular images after opt in")
    func cellularAfterOptIn() {
        policy.allowsCellularImages = true
        policy.setNetworkStateForTesting(isOnline: true, usesCellular: true)

        #expect(policy.canLoadRemoteImages)
        #expect(!policy.needsCellularPermissionPrompt)

        policy.setNetworkStateForTesting(isOnline: true, usesCellular: false)
    }
}
