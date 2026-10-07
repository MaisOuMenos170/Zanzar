import CoreLocation
import MapKit

/// Groups map pins that would overlap on screen.
///
/// The result is a pure function of the places and a quantized zoom level, so it is stable: panning never
/// changes it, and every item keeps the same `id` across calls. SwiftUI's `Map` relies on those ids to tell
/// an annotation that moved from one that was replaced; unstable ids make every pin blink.
enum MapPinClustering {
    /// Span below which every pin is shown individually (~250 m at the equator).
    static let individualSpanThreshold: Double = 0.00225

    /// Target span when expanding a cluster in one tap.
    static let zoomInSpanThreshold: Double = individualSpanThreshold * 0.8

    /// Zoom levels are half octaves of the visible span.
    private static let levelsPerOctave: Double = 2

    /// How far, in levels, the span has to move past a boundary before the level changes. Without it a
    /// camera hovering on a boundary would flip pins and clusters back and forth.
    private static let hysteresis: Double = 0.25

    /// Fraction of the level's span used as the grid cell size (~pin overlap on screen).
    private static let cellSizeFactor: Double = 0.042

    /// Fraction of the level's span used to merge markers that still overlap visually.
    private static let mergeDistanceFactor: Double = 0.055

    private struct GridCell: Hashable, Comparable {
        let row: Int
        let column: Int

        static func < (lhs: GridCell, rhs: GridCell) -> Bool {
            (lhs.row, lhs.column) < (rhs.row, rhs.column)
        }
    }

    // MARK: - Zoom level

    /// The zoom level for a visible span. Passing the previous level applies hysteresis around boundaries.
    static func zoomLevel(forSpan span: Double, previous: MapPinZoomLevel?) -> MapPinZoomLevel {
        let raw = log2(max(span, .leastNormalMagnitude)) * levelsPerOctave
        let individualEdge = log2(individualSpanThreshold) * levelsPerOctave

        switch previous {
        case .individual:
            if raw <= individualEdge + hysteresis { return .individual }
        case .grouped(let level):
            let staysInLevel = raw >= Double(level) - hysteresis && raw < Double(level + 1) + hysteresis
            if staysInLevel, raw > individualEdge - hysteresis { return .grouped(level) }
        case nil:
            break
        }

        return raw <= individualEdge ? .individual : .grouped(Int(floor(raw)))
    }

    // MARK: - Clustering

    static func cluster(places: [MapPlace], region: MKCoordinateRegion) -> [MapPinDisplayItem] {
        let span = max(region.span.latitudeDelta, region.span.longitudeDelta)
        return cluster(places: places, zoomLevel: zoomLevel(forSpan: span, previous: nil))
    }

    static func cluster(places: [MapPlace], zoomLevel: MapPinZoomLevel) -> [MapPinDisplayItem] {
        guard !places.isEmpty else { return [] }

        guard case .grouped(let level) = zoomLevel else {
            return sorted(places.map { .place($0) })
        }

        let span = pow(2, Double(level) / levelsPerOctave)
        let latitudeCellSize = span * cellSizeFactor

        // The grid is anchored to the world, not to the visible region, so a place stays in the same cell
        // wherever the camera is. Longitude cells widen towards the poles to stay roughly square.
        var buckets: [GridCell: [MapPlace]] = [:]
        for place in places {
            let row = Int(floor((place.latitude + 90) / latitudeCellSize))
            let rowCenterLatitude = (Double(row) + 0.5) * latitudeCellSize - 90
            let longitudeScale = max(cos(rowCenterLatitude * .pi / 180), 0.4)
            let longitudeCellSize = latitudeCellSize / longitudeScale
            let column = Int(floor((place.longitude + 180) / longitudeCellSize))
            buckets[GridCell(row: row, column: column), default: []].append(place)
        }

        let initialItems = buckets.keys.sorted().map { cell in
            displayItem(for: buckets[cell] ?? [])
        }

        return sorted(
            mergeOverlappingItems(initialItems, maxCentroidDistance: span * mergeDistanceFactor)
        )
    }

    /// A lone place stays a pin; several become a cluster whose id comes from its smallest member id, so the
    /// id survives members joining or leaving, and a merge keeps the id of one of the two clusters.
    private static func displayItem(for places: [MapPlace]) -> MapPinDisplayItem {
        if places.count == 1, let place = places.first {
            return .place(place)
        }
        // A canonical member order keeps the centroid identical however the cluster was assembled.
        let members = places.sorted { $0.id < $1.id }
        return .cluster(MapPinCluster(places: members, stableID: "cluster-\(members[0].id)"))
    }

    private static func mergeOverlappingItems(
        _ items: [MapPinDisplayItem],
        maxCentroidDistance: Double
    ) -> [MapPinDisplayItem] {
        var current = sorted(items)

        while let pair = firstOverlappingPair(in: current, maxCentroidDistance: maxCentroidDistance) {
            let mergedPlaces = uniquePlaces(current[pair.first].memberPlaces + current[pair.second].memberPlaces)
            current.remove(at: pair.second)
            current.remove(at: pair.first)
            current.append(displayItem(for: mergedPlaces))
            current = sorted(current)
        }

        return current
    }

    private static func firstOverlappingPair(
        in items: [MapPinDisplayItem],
        maxCentroidDistance: Double
    ) -> (first: Int, second: Int)? {
        for first in items.indices {
            for second in (first + 1) ..< items.count
            where coordinateDistance(from: items[first].coordinate, to: items[second].coordinate) <= maxCentroidDistance {
                return (first, second)
            }
        }
        return nil
    }

    private static func sorted(_ items: [MapPinDisplayItem]) -> [MapPinDisplayItem] {
        items.sorted { $0.id < $1.id }
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
