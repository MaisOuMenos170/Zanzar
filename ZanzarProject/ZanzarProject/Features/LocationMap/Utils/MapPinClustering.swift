import CoreLocation
import MapKit

enum MapPinClustering {
    /// Span below which every pin is shown individually (~250 m at the equator).
    private static let individualSpanThreshold: Double = 0.00225

    /// Fraction of the visible map span used as the clustering radius.
    private static let clusterRadiusFactor: Double = 0.048

    static func cluster(places: [MapPlace], region: MKCoordinateRegion) -> [MapPinDisplayItem] {
        guard !places.isEmpty else { return [] }

        let span = max(region.span.latitudeDelta, region.span.longitudeDelta)
        guard span > individualSpanThreshold else {
            return places.map { .place($0) }
        }

        let clusterRadius = span * clusterRadiusFactor
        var unclustered = places
        var displayItems: [MapPinDisplayItem] = []

        while !unclustered.isEmpty {
            let seed = unclustered.removeFirst()
            var members = [seed]

            var index = 0
            while index < unclustered.count {
                let candidate = unclustered[index]
                let isNearCluster = members.contains { member in
                    coordinateDistance(from: member.coordinate, to: candidate.coordinate) <= clusterRadius
                }

                if isNearCluster {
                    members.append(candidate)
                    unclustered.remove(at: index)
                } else {
                    index += 1
                }
            }

            if members.count == 1 {
                displayItems.append(.place(members[0]))
            } else {
                displayItems.append(.cluster(MapPinCluster(places: members)))
            }
        }

        return displayItems
    }

    private static func coordinateDistance(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) -> Double {
        let latitudeDelta = origin.latitude - destination.latitude
        let longitudeDelta = origin.longitude - destination.longitude
        return (latitudeDelta * latitudeDelta + longitudeDelta * longitudeDelta).squareRoot()
    }
}
