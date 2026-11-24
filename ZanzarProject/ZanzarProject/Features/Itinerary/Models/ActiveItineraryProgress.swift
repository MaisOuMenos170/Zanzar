import CoreGraphics
import Foundation

struct ActiveItineraryProgress: Equatable {
    enum StopState: Equatable {
        case done
        case current
        case upcoming
        case destination
    }

    let total: Int
    let completed: Int
    let nextPlaceID: String?
    let nextPlaceName: String?

    init(_ itinerary: ActiveItinerary) {
        total = itinerary.places.count
        completed = itinerary.places.filter(\.isCompleted).count
        let next = itinerary.places.first { !$0.isCompleted }
        nextPlaceID = next?.placeID
        nextPlaceName = next?.placeName
    }

    var currentIndex: Int {
        max(0, min(completed, total - 1))
    }

    var currentNumber: Int {
        currentIndex + 1
    }

    func state(at index: Int) -> StopState {
        if index < completed { return .done }
        if index == currentIndex { return .current }
        return index == total - 1 ? .destination : .upcoming
    }
}

enum ActiveItineraryRouteGeometry {
    static let designWidth: CGFloat = 360
    static let height: CGFloat = 227

    static let pathFrame = CGRect(x: 21.6, y: 122.6, width: 297.801, height: 43.5029)

    private static let designStops = [
        CGPoint(x: 32, y: 156.5),
        CGPoint(x: 140, y: 162.5),
        CGPoint(x: 229, y: 129.5),
        CGPoint(x: 319, y: 149.5)
    ]

    private static let pathHeights: [CGFloat] = [
        40.5, 31.6, 25.8, 23.9, 25.4, 30.8, 37.1, 41.0, 42.0, 38.8,
        30.6, 19.5, 10.2, 4.5, 1.9, 1.7, 3.7, 7.6, 13.4, 20.8, 27.5
    ]
    private static let pathSampleStep: CGFloat = 15

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

    static func pathY(atCardX cardX: CGFloat) -> CGFloat {
        let local = min(max(cardX - pathFrame.minX, 0), pathFrame.width)
        let position = local / pathSampleStep
        let lower = min(Int(position), pathHeights.count - 2)
        let fraction = position - CGFloat(lower)
        let height = pathHeights[lower] + (pathHeights[lower + 1] - pathHeights[lower]) * fraction
        return pathFrame.minY + height
    }
}
