import CoreLocation
import Testing
@testable import ZanzarProject

@Suite("ApplePlaceResultMapper")
struct ApplePlaceResultMapperTests {
    private func map(
        name: String?,
        hasCategory: Bool,
        fullAddress: String?,
        shortAddress: String? = nil
    ) -> SuggestedPlace? {
        ApplePlaceResultMapper.place(
            name: name,
            hasCategory: hasCategory,
            fullAddress: fullAddress,
            shortAddress: shortAddress,
            coordinate: CLLocationCoordinate2D(latitude: -25.44, longitude: -49.24)
        )
    }

    @Test("a point of interest keeps its name and its address")
    func pointOfInterest() {
        let place = map(
            name: "Jardim Botânico de Curitiba",
            hasCategory: true,
            fullAddress: "Rua Engenheiro Ostoja Roguski, 350, Curitiba - PR, Brasil"
        )

        #expect(place?.name == "Jardim Botânico de Curitiba")
        #expect(place?.address == "Rua Engenheiro Ostoja Roguski, 350, Curitiba - PR, Brasil")
        #expect(place?.latitude == -25.44)
        #expect(place?.longitude == -49.24)
    }

    @Test("a point of interest keeps its name even when the address repeats it")
    func pointOfInterestNamedAfterItsStreet() {
        let place = map(
            name: "Rua Augusta",
            hasCategory: true,
            fullAddress: "Rua Augusta, Curitiba"
        )

        #expect(place?.name == "Rua Augusta")
    }

    @Test("a result named after its own address has no name")
    func addressHasNoName() {
        let place = map(
            name: "Rua Engenheiro Ostoja Roguski, 360",
            hasCategory: false,
            fullAddress: "Rua Engenheiro Ostoja Roguski, 360, Jardim Botânico, Curitiba - PR, Brasil",
            shortAddress: "Rua Engenheiro Ostoja Roguski, 360"
        )

        #expect(place?.name == nil)
        #expect(place?.address == "Rua Engenheiro Ostoja Roguski, 360, Jardim Botânico, Curitiba - PR, Brasil")
    }

    @Test("accents and case do not hide that the name is the address")
    func nameMatchIgnoresAccentsAndCase() {
        let place = map(
            name: "JARDIM BOTANICO",
            hasCategory: false,
            fullAddress: "Jardim Botânico, Curitiba - PR, Brasil"
        )

        #expect(place?.name == nil)
    }

    @Test("a result with a name that is not in its address keeps the name")
    func uncategorizedButNamed() {
        let place = map(
            name: "Edifício Alvorada",
            hasCategory: false,
            fullAddress: "Rua A, 10, Curitiba - PR, Brasil"
        )

        #expect(place?.name == "Edifício Alvorada")
    }

    @Test("a named place without an address keeps only the name")
    func noAddress() {
        let place = map(name: "Padaria Central", hasCategory: true, fullAddress: nil)

        #expect(place?.name == "Padaria Central")
        #expect(place?.address == nil)
    }

    @Test("blank texts count as missing")
    func blankTexts() {
        let place = map(name: "  ", hasCategory: true, fullAddress: "Rua A, 10")

        #expect(place?.name == nil)
        #expect(place?.address == "Rua A, 10")
    }

    @Test("a result with neither a name nor an address is dropped")
    func nothingToShow() {
        #expect(map(name: nil, hasCategory: false, fullAddress: nil) == nil)
        #expect(map(name: " ", hasCategory: true, fullAddress: "") == nil)
    }

    @Test("the search area covers Curitiba and its neighbors but not other cities")
    func searchArea() {
        #expect(PlaceSearchArea.contains(latitude: -25.4284, longitude: -49.2733))
        // São José dos Pinhais
        #expect(PlaceSearchArea.contains(latitude: -25.53, longitude: -49.20))
        // São Paulo
        #expect(!PlaceSearchArea.contains(latitude: -23.55, longitude: -46.63))
        // Paranaguá
        #expect(!PlaceSearchArea.contains(latitude: -25.52, longitude: -48.51))
    }
}
