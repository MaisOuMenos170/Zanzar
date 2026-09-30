import CoreLocation
import MapKit

enum MapPinClustering {
    /// Span below which every pin is shown individually (~250 m at the equator).
    private static let individualSpanThreshold: Double = 0.00225

    /// Fraction of the visible map span used as the grid cell size (~pin overlap on screen).
    private static let cellSizeFactor: Double = 0.034

    private struct GridCell: Hashable {
        let x: Int
        let y: Int
    }

    static func cluster(places: [MapPlace], region: MKCoordinateRegion) -> [MapPinDisplayItem] {
        guard !places.isEmpty else { return [] }

        let span = max(region.span.latitudeDelta, region.span.longitudeDelta)
        guard span > individualSpanThreshold else {
            return places.map { .place($0) }
        }

        let latitudeCellSize = span * cellSizeFactor
        let longitudeScale = cos(region.center.latitude * .pi / 180)
        let longitudeCellSize = latitudeCellSize / max(longitudeScale, 0.4)

        var buckets: [GridCell: [MapPlace]] = [:]
        for place in places {
            let cell = GridCell(
                x: Int(floor((place.longitude - region.center.longitude) / longitudeCellSize)),
                y: Int(floor((place.latitude - region.center.latitude) / latitudeCellSize))
            )
            buckets[cell, default: []].append(place)
        }

        return buckets.values.map { members in
            if members.count == 1 {
                .place(members[0])
            } else {
                .cluster(MapPinCluster(places: members))
            }
        }
    }
}
