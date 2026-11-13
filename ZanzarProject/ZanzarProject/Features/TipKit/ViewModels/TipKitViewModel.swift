import Observation
import TipKit

@Observable
final class TipKitViewModel {
    private let service: TipKitServicing
    
    var isConfiguring = false
    var configurationError: String?
    var isResetting = false
    
    init(service: TipKitServicing = TipKitService.shared) {
        self.service = service
    }
    
    /// Configures TipKit on app launch.
    @MainActor
    func configure() async {
        isConfiguring = true
        configurationError = nil
        defer { isConfiguring = false }
        
        do {
            try await service.configure()
        } catch {
            configurationError = error.localizedDescription
        }
    }
    
    /// Resets all tip display state - for "Show tutorial again" feature.
    @MainActor
    func resetAllTips() async {
        isResetting = true
        defer { isResetting = false }
        
        await service.resetAllTips()
    }
    
    /// Marks a tip parameter as seen/updated.
    /// Call this when the user performs the action the tip teaches.
    @MainActor
    func markTipParameterAsSeen(_ parameter: inout Bool) {
        parameter = true
    }
}