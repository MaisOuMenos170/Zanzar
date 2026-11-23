import Foundation

/// Where the backend accepts suggestions (`SERVICE_AREA` in `ZanzarBackend/src/constants/place-suggestions.ts`):
/// Curitiba and its metropolitan region. Checked up front so a shared place outside it never spends a daily
/// suggestion on a sure refusal.
nonisolated enum ServiceArea {
    static let longitudes: ClosedRange<Double> = -49.55...(-49.0)
    static let latitudes: ClosedRange<Double> = -25.8...(-25.15)

    static func contains(latitude: Double, longitude: Double) -> Bool {
        latitudes.contains(latitude) && longitudes.contains(longitude)
    }
}
