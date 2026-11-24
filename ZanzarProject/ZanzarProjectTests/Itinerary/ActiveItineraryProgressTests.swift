import CoreGraphics
import Foundation
import Testing
@testable import ZanzarProject

@Suite("ActiveItineraryProgress")
struct ActiveItineraryProgressTests {
    private static func itinerary(completed: Int, total: Int, named: Bool = true) -> ActiveItinerary {
        ActiveItinerary(
            templateID: "1",
            slug: "centro",
            name: "Centro",
            description: "",
            category: "historic",
            routeType: named ? .fixed : .free,
            objectives: [],
            targetCategory: nil,
            targetCount: nil,
            startedAt: .now,
            places: (0..<total).map { index in
                ItinerarySlot(
                    id: "\(index)",
                    placeID: named || index < completed ? "p\(index)" : nil,
                    placeName: named || index < completed ? "Lugar \(index)" : nil,
                    isCompleted: index < completed,
                    completedAt: nil,
                    stampID: nil
                )
            }
        )
    }

    @Test("two stops done out of four: heading to the third")
    func middleOfTheRoute() {
        let progress = ActiveItineraryProgress(Self.itinerary(completed: 2, total: 4))

        #expect(progress.currentIndex == 2)
        #expect(progress.currentNumber == 3)
        #expect(progress.total == 4)
        #expect(progress.nextPlaceID == "p2")
        #expect(progress.nextPlaceName == "Lugar 2")
    }

    @Test("stops are done, current, upcoming and the last one is the destination")
    func stopStates() {
        let progress = ActiveItineraryProgress(Self.itinerary(completed: 1, total: 5))

        #expect((0..<5).map(progress.state(at:)) == [.done, .current, .upcoming, .upcoming, .destination])
    }

    @Test("heading to the last stop, the avatar stands on it")
    func lastStopIsCurrent() {
        let progress = ActiveItineraryProgress(Self.itinerary(completed: 3, total: 4))

        #expect(progress.state(at: 3) == .current)
    }

    @Test("a roteiro that has just started begins at the first stop")
    func justStarted() {
        let progress = ActiveItineraryProgress(Self.itinerary(completed: 0, total: 4))

        #expect(progress.currentNumber == 1)
        #expect(progress.state(at: 0) == .current)
    }

    @Test("a free route has no next place until the user checks in")
    func freeRouteHasNoNextPlace() {
        let progress = ActiveItineraryProgress(Self.itinerary(completed: 1, total: 3, named: false))

        #expect(progress.currentNumber == 2)
        #expect(progress.nextPlaceID == nil)
        #expect(progress.nextPlaceName == nil)
    }

    @Test("with everything done it stays on the last stop instead of running past it")
    func everythingDone() {
        let progress = ActiveItineraryProgress(Self.itinerary(completed: 4, total: 4))

        #expect(progress.currentIndex == 3)
        #expect(progress.currentNumber == 4)
    }

    // MARK: - Route geometry

    @Test("four stops sit where the design puts them")
    func designStops() {
        let centers = ActiveItineraryRouteGeometry.stopCenters(count: 4)

        #expect(centers == [
            CGPoint(x: 32, y: 156.5), CGPoint(x: 140, y: 162.5),
            CGPoint(x: 229, y: 129.5), CGPoint(x: 319, y: 149.5)
        ])
    }

    @Test("other counts spread from the first stop to the last, left to right, on the path")
    func otherCounts() {
        for count in [1, 2, 3, 5, 8] {
            let centers = ActiveItineraryRouteGeometry.stopCenters(count: count)

            #expect(centers.count == count)
            #expect(centers.map(\.x) == centers.map(\.x).sorted())
            #expect(centers.last?.x == 319)
            for center in centers {
                #expect(center.y >= ActiveItineraryRouteGeometry.pathFrame.minY)
                #expect(center.y <= ActiveItineraryRouteGeometry.pathFrame.maxY)
            }
        }
        #expect(ActiveItineraryRouteGeometry.stopCenters(count: 0).isEmpty)
    }
}
