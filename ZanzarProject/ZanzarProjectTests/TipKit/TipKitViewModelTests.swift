import Testing
import TipKit
@testable import ZanzarProject

@Suite("TipKitViewModel")
struct TipKitViewModelTests {
    
    @Test("Configure calls service.configure")
    func configure() async throws {
        let mockService = MockTipKitService()
        let viewModel = TipKitViewModel(service: mockService)
        
        await viewModel.configure()
        
        #expect(mockService.configureCalled == true)
        #expect(viewModel.isConfiguring == false)
        #expect(viewModel.configurationError == nil)
    }
    
    @Test("Configure sets error on failure")
    func configureFailure() async throws {
        let mockService = MockTipKitService()
        mockService.shouldFailConfigure = true
        let viewModel = TipKitViewModel(service: mockService)
        
        await viewModel.configure()
        
        #expect(mockService.configureCalled == true)
        #expect(viewModel.configurationError != nil)
    }
    
    @Test("Reset all tips calls service.resetAllTips")
    func resetAllTips() async throws {
        let mockService = MockTipKitService()
        let viewModel = TipKitViewModel(service: mockService)
        
        await viewModel.resetAllTips()
        
        #expect(mockService.resetAllTipsCalled == true)
        #expect(viewModel.isResetting == false)
    }
    
    @Test("Initial state is correct")
    func initialState() async throws {
        let mockService = MockTipKitService()
        let viewModel = TipKitViewModel(service: mockService)
        
        #expect(viewModel.isConfiguring == false)
        #expect(viewModel.configurationError == nil)
        #expect(viewModel.isResetting == false)
    }
}

final class MockTipKitService: TipKitServicing, @unchecked Sendable {
    var configureCalled = false
    var resetAllTipsCalled = false
    var shouldFailConfigure = false
    var lastTipIdentifier: String?
    var configureError: Error?
    
    func configure() async throws {
        configureCalled = true
        if shouldFailConfigure {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Configure failed"])
        }
    }
    
    func resetAllTips() async {
        resetAllTipsCalled = true
    }
    
    func tip(for identifier: String) -> (any Tip)? {
        lastTipIdentifier = identifier
        return nil
    }
}