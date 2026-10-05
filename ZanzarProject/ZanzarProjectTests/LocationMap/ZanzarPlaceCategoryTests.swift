import Testing
@testable import ZanzarProject

@Suite("ZanzarPlaceCategory")
struct ZanzarPlaceCategoryTests {
    @Test("Each category maps to the Figma pin icon")
    func categoryIconsMatchFigma() {
        #expect(ZanzarPlaceCategory.restaurant.pinIconName == "fork.knife")
        #expect(ZanzarPlaceCategory.bar.pinIconName == "wineglass")
        #expect(ZanzarPlaceCategory.cafe.pinIconName == "cup.and.heat.waves.fill")
        #expect(ZanzarPlaceCategory.museum.pinIconName == "building.columns.fill")
        #expect(ZanzarPlaceCategory.park.pinIconName == "leaf")
        #expect(ZanzarPlaceCategory.tourist.pinIconName == "signpost.right.and.left")
        #expect(ZanzarPlaceCategory.historic.pinIconName == "scroll")
        #expect(ZanzarPlaceCategory.curiosity.pinIconName == "eyes.inverse")
        #expect(ZanzarPlaceCategory.party.pinIconName == "party.popper")
        #expect(ZanzarPlaceCategory.unknown.pinIconName == "mappin")
    }

    @Test("Unknown backend category maps to unknown")
    func unknownCategoryMapping() {
        #expect(ZanzarPlaceCategory(rawCategory: "not_a_category") == .unknown)
    }
}
