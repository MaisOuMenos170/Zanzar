import Foundation
import Observation

@Observable
final class LocationMarkViewModel {
    private let service: LocationMarkServicing

    var markedLocation: LocationMark?
    var isLoading = false
    var errorMessage: String?
    var isAuthorizationDenied = false
    var isPresentingError = false

    init(service: LocationMarkServicing = LocationMarkService()) {
        self.service = service
    }

    func markCurrentLocation() async {
        isLoading = true
        errorMessage = nil
        isAuthorizationDenied = false
        isPresentingError = false
        defer { isLoading = false }

        do {
            let response = try await service.currentLocation()
            markedLocation = LocationMark(
                id: UUID(),
                latitude: response.latitude,
                longitude: response.longitude,
                capturedAt: response.capturedAt
            )
        } catch let error as LocationMarkError {
            isAuthorizationDenied = error.isAuthorizationFailure
            errorMessage = error.errorDescription
            isPresentingError = !error.isAuthorizationFailure
        } catch {
            isAuthorizationDenied = false
            errorMessage = error.localizedDescription
            isPresentingError = true
        }
    }
}
