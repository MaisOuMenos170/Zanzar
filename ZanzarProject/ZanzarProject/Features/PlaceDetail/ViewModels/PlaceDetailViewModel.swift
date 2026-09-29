import Foundation
import Observation

@Observable
final class PlaceDetailViewModel {
    private let service: PlaceDetailServicing
    private let place: MapPlace

    var detail: PlaceDetail?
    var isLoading = false
    var isCheckingIn = false
    var errorMessage: String?

    init(place: MapPlace, service: PlaceDetailServicing = PlaceDetailService()) {
        self.place = place
        self.service = service
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            detail = try await service.fetchPlaceDetail(for: place)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func performCheckIn() async {
        guard var currentDetail = detail, !currentDetail.hasCheckedIn else { return }

        isCheckingIn = true
        errorMessage = nil
        defer { isCheckingIn = false }

        do {
            let updatedDetail = try await service.checkIn(at: currentDetail.id)
            currentDetail.hasCheckedIn = updatedDetail.hasCheckedIn
            detail = currentDetail
        } catch is CancellationError {
            return
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

}
