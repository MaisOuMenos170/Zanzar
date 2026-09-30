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

        #expect(items.count == 3)
        #expect(items.allSatisfy { item in
            if case .place = item { true } else { false }
        })
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
}
