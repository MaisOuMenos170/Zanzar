import CoreLocation
import MapKit

enum MapPinClustering {
    /// Span below which every pin is shown individually (~250 m at the equator).
    static let individualSpanThreshold: Double = 0.00225

    /// Target span when expanding a cluster in one tap.
    static let zoomInSpanThreshold: Double = individualSpanThreshold * 0.8

    /// Fraction of the visible map span used as the grid cell size (~pin overlap on screen).
    private static let cellSizeFactor: Double = 0.042

    /// Fraction of the visible map span used to merge markers that still overlap visually.
    private static let mergeDistanceFactor: Double = 0.055

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

        let initialItems = buckets.map { cell, members in
            displayItem(for: members, stableID: "cluster-\(cell.column)-\(cell.row)")
        }

        return mergeOverlappingItems(
            initialItems,
            maxCentroidDistance: span * mergeDistanceFactor
        )
    }

    private static func displayItem(for places: [MapPlace], stableID: String) -> MapPinDisplayItem {
        if places.count == 1, let place = places.first {
            .place(place)
        } else {
            .cluster(MapPinCluster(places: places, stableID: stableID))
        }
    }

    private static func mergeOverlappingItems(
        _ items: [MapPinDisplayItem],
        maxCentroidDistance: Double
    ) -> [MapPinDisplayItem] {
        var current = items

        while true {
            var mergedAny = false

            for firstIndex in current.indices {
                for secondIndex in (firstIndex + 1) ..< current.count {
                    let firstItem = current[firstIndex]
                    let secondItem = current[secondIndex]
                    let distance = coordinateDistance(
                        from: firstItem.coordinate,
                        to: secondItem.coordinate
                    )

                    guard distance <= maxCentroidDistance else { continue }

                    let mergedPlaces = uniquePlaces(
                        firstItem.memberPlaces + secondItem.memberPlaces
                    )
                    let stableID = min(firstItem.id, secondItem.id)
                    let mergedItem = displayItem(for: mergedPlaces, stableID: stableID)

                    current.remove(at: secondIndex)
                    current.remove(at: firstIndex)
                    current.append(mergedItem)
                    mergedAny = true
                    break
                }

                if mergedAny { break }
            }

            if !mergedAny { break }
        }

        return current
    }

    private static func uniquePlaces(_ places: [MapPlace]) -> [MapPlace] {
        var seenIDs = Set<String>()
        return places.filter { seenIDs.insert($0.id).inserted }
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

private extension MapPinDisplayItem {
    var memberPlaces: [MapPlace] {
        switch self {
        case .place(let place):
            [place]
        case .cluster(let cluster):
            cluster.places
        }
    }
}
