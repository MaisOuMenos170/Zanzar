import CoreLocation
import Foundation

protocol LocationMarkServicing: Sendable {
    func currentLocation() async throws -> LocationMarkResponse
}

struct LocationMarkResponse: Sendable, Equatable {
    let latitude: Double
    let longitude: Double
    let capturedAt: Date
    let horizontalAccuracy: Double
}

enum LocationMarkError: Error, LocalizedError, Equatable, Sendable {
    case authorizationDenied
    case locationServicesDisabled
    case unavailable

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            "O acesso à localização foi recusado. Ative-o em Ajustes para marcar o ponto."
        case .locationServicesDisabled:
            "Os Serviços de Localização estão desativados neste dispositivo."
        case .unavailable:
            "Não foi possível obter uma localização precisa. Tente de novo em um lugar aberto."
        }
    }

    var isAuthorizationFailure: Bool {
        self == .authorizationDenied || self == .locationServicesDisabled
    }
}

final class LocationMarkService: LocationMarkServicing {
    private let accuracyThreshold: CLLocationAccuracy = 100
    private let maximumLocationAge: TimeInterval = 15
    private let timeout: Duration = .seconds(20)

    func currentLocation() async throws -> LocationMarkResponse {
        let session = CLServiceSession(authorization: .whenInUse)
        return try await fetchFirstAccurateFix(keeping: session)
    }

    private func fetchFirstAccurateFix(keeping session: CLServiceSession) async throws -> LocationMarkResponse {
        try await withThrowingTaskGroup(of: LocationMarkResponse.self) { group in
            group.addTask {
                try await self.firstAccurateLocation(keeping: session)
            }
            group.addTask {
                try await Task.sleep(for: self.timeout)
                throw LocationMarkError.unavailable
            }
            defer { group.cancelAll() }

            guard let response = try await group.next() else {
                throw LocationMarkError.unavailable
            }
            return response
        }
    }

    private func firstAccurateLocation(keeping session: CLServiceSession) async throws -> LocationMarkResponse {
        for try await update in CLLocationUpdate.liveUpdates(.default) {
            try Task.checkCancellation()

            if update.authorizationDenied {
                throw LocationMarkError.authorizationDenied
            }
            if update.authorizationDeniedGlobally {
                throw LocationMarkError.locationServicesDisabled
            }
            if update.locationUnavailable {
                continue
            }

            guard let location = update.location else { continue }
            guard location.horizontalAccuracy >= 0,
                  location.horizontalAccuracy < accuracyThreshold else {
                continue
            }
            guard abs(location.timestamp.timeIntervalSinceNow) < maximumLocationAge else {
                continue
            }

            _ = session
            return LocationMarkResponse(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                capturedAt: location.timestamp,
                horizontalAccuracy: location.horizontalAccuracy
            )
        }

        throw LocationMarkError.unavailable
    }
}
