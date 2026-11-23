import CoreGraphics
import Foundation

/// Where the user is in the roteiro they follow, as the "Roteiro em andamento" card tells it: how many stops are
/// done, which one is next, and where each stop sits on the drawn route.
struct ActiveItineraryProgress: Equatable {
    enum StopState: Equatable {
        /// Already visited.
        case done
        /// The stop the user is heading to; the avatar stands on it.
        case current
        /// A stop after the current one that is not the last.
        case upcoming
        /// The last stop of the roteiro, when it is not the current one.
        case destination
    }

    let total: Int
    let completed: Int
    /// The place of the stop the user is heading to. Free routes only know it once the user checks in.
    let nextPlaceID: String?
    let nextPlaceName: String?

    init(_ itinerary: ActiveItinerary) {
        total = itinerary.places.count
        completed = itinerary.places.filter(\.isCompleted).count
        let next = itinerary.places.first { !$0.isCompleted }
        nextPlaceID = next?.placeID
        nextPlaceName = next?.placeName
    }

    /// Zero-based index of the current stop; the last one when everything is done.
    var currentIndex: Int {
        max(0, min(completed, total - 1))
    }

    /// "3" in "3 de 4 paradas".
    var currentNumber: Int {
        currentIndex + 1
    }

    func state(at index: Int) -> StopState {
        if index < completed { return .done }
        if index == currentIndex { return .current }
        return index == total - 1 ? .destination : .upcoming
    }
}

/// The drawn route of the card, in the 360 pt wide space of the design (Figma "checkin v2", node 2046:13579).
enum ActiveItineraryRouteGeometry {
    static let designWidth: CGFloat = 360
    static let height: CGFloat = 227

    /// Where the dashed path image sits and how big it is (`CheckInActiveRoutePath`).
    static let pathFrame = CGRect(x: 21.6, y: 122.6, width: 297.801, height: 43.5029)

    /// The stops of the design, which has four. Other counts are spread over the same path.
    private static let designStops = [
        CGPoint(x: 32, y: 156.5),
        CGPoint(x: 140, y: 162.5),
        CGPoint(x: 229, y: 129.5),
        CGPoint(x: 319, y: 149.5)
    ]

    /// Height of the path (in the path image's own space) at every 15 pt of its width.
    private static let pathHeights: [CGFloat] = [
        40.5, 31.6, 25.8, 23.9, 25.4, 30.8, 37.1, 41.0, 42.0, 38.8,
        30.6, 19.5, 10.2, 4.5, 1.9, 1.7, 3.7, 7.6, 13.4, 20.8, 27.5
    ]
    private static let pathSampleStep: CGFloat = 15

    /// The center of each stop, left to right.
    static func stopCenters(count: Int) -> [CGPoint] {
        guard count > 0 else { return [] }
        if count == designStops.count { return designStops }

        let first = designStops[0].x
        let last = designStops[designStops.count - 1].x
        return (0..<count).map { index in
            let centerX = count == 1 ? last : first + (last - first) * CGFloat(index) / CGFloat(count - 1)
            return CGPoint(x: centerX, y: pathY(atCardX: centerX))
        }
    }

    /// The path's height on the card at `x`, by interpolating the samples.
    static func pathY(atCardX cardX: CGFloat) -> CGFloat {
        let local = min(max(cardX - pathFrame.minX, 0), pathFrame.width)
        let position = local / pathSampleStep
        let lower = min(Int(position), pathHeights.count - 2)
        let fraction = position - CGFloat(lower)
        let height = pathHeights[lower] + (pathHeights[lower + 1] - pathHeights[lower]) * fraction
        return pathFrame.minY + height
    }
}
