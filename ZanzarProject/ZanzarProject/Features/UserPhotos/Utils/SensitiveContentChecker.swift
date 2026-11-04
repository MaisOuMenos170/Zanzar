import CoreGraphics
import SensitiveContentAnalysis

/// Apple's on-device nudity check. It only runs when the user turned on Sensitive Content Warning (or
/// Communication Safety) in Settings, and only with the `com.apple.developer.sensitivecontentanalysis.client`
/// entitlement; otherwise it answers `nil` ("could not check"). It is an extra barrier, never the only one.
protocol SensitiveContentChecking: Sendable {
    func isSensitive(_ image: CGImage) async -> Bool?
}

nonisolated struct SensitiveContentChecker: SensitiveContentChecking {
    func isSensitive(_ image: CGImage) async -> Bool? {
        let analyzer = SCSensitivityAnalyzer()
        guard analyzer.analysisPolicy != .disabled else { return nil }
        do {
            return try await analyzer.analyzeImage(image).isSensitive
        } catch {
            AppLog.userPhotos.warning("Sensitive content analysis unavailable")
            return nil
        }
    }
}
