import Observation

@Observable
final class ItineraryViewModel {
    private let service: ItineraryServicing

    var isLoading = false
    var errorMessage: String?

    init(service: ItineraryServicing = ItineraryService()) {
        self.service = service
    }

    // TODO: implement the feature's actions, e.g.:
    // func submit() async {
    //     isLoading = true
    //     defer { isLoading = false }
    //     do {
    //         _ = try await service.submitItinerary(ItineraryRequest())
    //     } catch {
    //         errorMessage = error.localizedDescription
    //     }
    // }
}
