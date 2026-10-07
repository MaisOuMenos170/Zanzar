import MapKit
import Testing
@testable import ZanzarProject

@Suite("MapPinClustering")
struct MapPinClusteringTests {
    private func place(
        id: String,
        latitude: Double,
        longitude: Double
    ) -> MapPlace {
        MapPlace(
            id: id,
            name: id,
            latitude: latitude,
            longitude: longitude,
            category: .museum,
            distanceMeters: 0
        )
    }

    private func region(span: Double) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -25.43, longitude: -49.27),
            span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        )
    }

    @Test("Empty places returns no display items")
    func emptyPlaces() {
        let items = MapPinClustering.cluster(places: [], region: region(span: 0.05))
        #expect(items.isEmpty)
    }

    @Test("Zoomed-in map shows every place individually")
    func zoomedInShowsIndividuals() {
        let places = [
            place(id: "a", latitude: -25.430, longitude: -49.270),
            place(id: "b", latitude: -25.4301, longitude: -49.2701)
        ]

        let items = MapPinClustering.cluster(places: places, region: region(span: 0.001))

        #expect(items.count == 2)
        #expect(items.allSatisfy { item in
            if case .place = item { true } else { false }
        })
    }

    @Test("Zoomed-out map groups nearby places into a cluster")
    func zoomedOutGroupsNearbyPlaces() {
        let places = [
            place(id: "a", latitude: -25.430, longitude: -49.270),
            place(id: "b", latitude: -25.4302, longitude: -49.2702),
            place(id: "c", latitude: -25.500, longitude: -49.350)
        ]

        let items = MapPinClustering.cluster(places: places, region: region(span: 0.05))

        #expect(items.count == 2)

        let cluster = items.compactMap { item -> MapPinCluster? in
            if case .cluster(let cluster) = item { cluster } else { nil }
        }.first
        #expect(cluster?.count == 2)

        let individual = items.compactMap { item -> MapPlace? in
            if case .place(let place) = item { place } else { nil }
        }.first
        #expect(individual?.id == "c")
    }

    @Test("Pins far apart in a chain are not grouped into one cluster")
    func chainDoesNotOverCluster() {
        let places = [
            place(id: "a", latitude: -25.430, longitude: -49.270),
            place(id: "b", latitude: -25.432, longitude: -49.270),
            place(id: "c", latitude: -25.434, longitude: -49.270)
        ]

        let items = MapPinClustering.cluster(places: places, region: region(span: 0.05))

        #expect(items.count == 2)

        let cluster = items.compactMap { item -> MapPinCluster? in
            if case .cluster(let cluster) = item { cluster } else { nil }
        }.first
        #expect(cluster?.count == 2)

        let individuals = items.compactMap { item -> MapPlace? in
            if case .place(let place) = item { place } else { nil }
        }
        #expect(individuals.count == 1)
        #expect(individuals[0].id == "a" || individuals[0].id == "c")
    }

    @Test("Dense overlapping places merge into a single cluster marker")
    func densePlacesMergeIntoOneCluster() {
        let places = (0 ..< 8).map { index in
            place(
                id: "\(index)",
                latitude: -25.430 + (Double(index) * 0.00025),
                longitude: -49.270 + (Double(index) * 0.00025)
            )
        }

        let items = MapPinClustering.cluster(places: places, region: region(span: 0.05))

        #expect(items.count == 1)
        if case .cluster(let cluster) = items[0] {
            #expect(cluster.count == 8)
        } else {
            Issue.record("Expected a single cluster display item")
        }
    }

    @Test("Single place never becomes a cluster")
    func singlePlaceStaysIndividual() {
        let places = [place(id: "solo", latitude: -25.430, longitude: -49.270)]

        let items = MapPinClustering.cluster(places: places, region: region(span: 0.05))

        #expect(items.count == 1)
        if case .place(let place) = items[0] {
            #expect(place.id == "solo")
        } else {
            Issue.record("Expected a single place item")
        }
    }

    // MARK: - Stability

    private var scatteredPlaces: [MapPlace] {
        (0 ..< 40).map { index in
            place(
                id: "p\(index)",
                latitude: -25.43 + Double(index % 8) * 0.0013,
                longitude: -49.27 + Double(index / 8) * 0.0017
            )
        }
    }

    private func ids(_ items: [MapPinDisplayItem]) -> [String] {
        items.map(\.id)
    }

    @Test("Panning the camera does not change the items or their ids")
    func panningKeepsItemsStable() {
        let places = scatteredPlaces
        let reference = MapPinClustering.cluster(places: places, region: region(span: 0.05))

        for offset in stride(from: -0.03, through: 0.03, by: 0.0037) {
            let panned = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: -25.43 + offset, longitude: -49.27 - offset / 2),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            #expect(MapPinClustering.cluster(places: places, region: panned) == reference)
        }
    }

    @Test("The same input always gives the same result")
    func clusteringIsDeterministic() {
        let places = scatteredPlaces
        let first = MapPinClustering.cluster(places: places, zoomLevel: .grouped(-8))

        for _ in 0 ..< 50 {
            #expect(MapPinClustering.cluster(places: places.shuffled(), zoomLevel: .grouped(-8)) == first)
        }
    }

    @Test("A cluster takes its id from its smallest member id")
    func clusterIDComesFromSmallestMember() {
        let places = [
            place(id: "z", latitude: -25.430, longitude: -49.270),
            place(id: "m", latitude: -25.4301, longitude: -49.2701)
        ]

        let items = MapPinClustering.cluster(places: places, region: region(span: 0.05))

        #expect(ids(items) == ["cluster-m"])
    }

    @Test("Items come back in a stable order")
    func itemsAreSortedByID() {
        let items = MapPinClustering.cluster(places: scatteredPlaces, zoomLevel: .individual)

        #expect(ids(items) == ids(items).sorted())
    }

    @Test("Zooming in splits a cluster without renaming the pins that were already individual")
    func zoomingKeepsSoloPinIDs() {
        let places = [
            place(id: "a", latitude: -25.430, longitude: -49.270),
            place(id: "b", latitude: -25.4302, longitude: -49.2702),
            place(id: "far", latitude: -25.500, longitude: -49.350)
        ]

        let zoomedOut = MapPinClustering.cluster(places: places, region: region(span: 0.05))
        let zoomedIn = MapPinClustering.cluster(places: places, region: region(span: 0.001))

        #expect(ids(zoomedOut).contains("far"))
        #expect(ids(zoomedIn).contains("far"))
    }

    // MARK: - Zoom level

    @Test("Spans inside one level map to that level")
    func zoomLevelBucketsSpans() {
        let level = MapPinClustering.zoomLevel(forSpan: 0.05, previous: nil)

        #expect(level == MapPinClustering.zoomLevel(forSpan: 0.048, previous: nil))
        #expect(level != MapPinClustering.zoomLevel(forSpan: 0.4, previous: nil))
    }

    @Test("Close spans are individual")
    func zoomLevelIndividual() {
        #expect(MapPinClustering.zoomLevel(forSpan: 0.001, previous: nil) == .individual)
    }

    @Test("Hysteresis keeps the level when the span barely crosses a boundary")
    func zoomLevelHysteresis() {
        let level = MapPinClustering.zoomLevel(forSpan: 0.05, previous: nil)
        guard case .grouped(let value) = level else {
            Issue.record("Expected a grouped level")
            return
        }
        let boundary = pow(2, Double(value + 1) / 2)

        #expect(MapPinClustering.zoomLevel(forSpan: boundary * 1.04, previous: level) == level)
        #expect(MapPinClustering.zoomLevel(forSpan: boundary * 1.4, previous: level) != level)
    }

    @Test("Hysteresis also applies at the individual threshold")
    func zoomLevelHysteresisAtIndividualEdge() {
        let justAbove = MapPinClustering.individualSpanThreshold * 1.03

        #expect(MapPinClustering.zoomLevel(forSpan: justAbove, previous: .individual) == .individual)
        #expect(MapPinClustering.zoomLevel(forSpan: justAbove, previous: nil) != .individual)
    }
}
