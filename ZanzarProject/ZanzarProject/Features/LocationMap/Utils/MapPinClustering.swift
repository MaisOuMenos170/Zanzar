import CoreLocation
import MapKit

enum MapPinClustering {
    /// Span below which every pin is shown individually (~250 m at the equator).
    static let individualSpanThreshold: Double = 0.00225

    /// Target span when expanding a cluster in one tap.
    static let zoomInSpanThreshold: Double = individualSpanThreshold * 0.8

    /// Fraction of the visible map span used as the grid cell size (~pin overlap on screen).
    private static let cellSizeFactor: Double = 0.034

    private struct GridCell: Hashable {
        let column: Int
        let row: Int
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
        let originLatitude = region.center.latitude - (region.span.latitudeDelta / 2)
        let originLongitude = region.center.longitude - (region.span.longitudeDelta / 2)

        var buckets: [GridCell: [MapPlace]] = [:]
        for place in places {
            let cell = GridCell(
                column: Int(floor((place.longitude - originLongitude) / longitudeCellSize)),
                row: Int(floor((place.latitude - originLatitude) / latitudeCellSize))
            )
            buckets[cell, default: []].append(place)
        }

        return buckets.map { cell, members in
            if members.count == 1 {
                .place(members[0])
            } else {
                .cluster(MapPinCluster(cellColumn: cell.column, cellRow: cell.row, places: members))
            }
        }
    }
}
