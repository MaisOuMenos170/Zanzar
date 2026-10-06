import Testing
@testable import ZanzarProject

@Suite("PlaceDisplayNameResolver")
struct PlaceDisplayNameResolverTests {
    @Test("Uses nickname when present")
    func usesNickname() {
        let displayName = PlaceDisplayNameResolver.displayName(
            nickname: "Casa das Galinhas",
            name: "Restaurante Original"
        )

        #expect(displayName == "Casa das Galinhas")
    }

    @Test("Falls back to name when nickname is nil or empty")
    func fallsBackToName() {
        #expect(
            PlaceDisplayNameResolver.displayName(nickname: nil, name: "Museu Oscar Niemeyer")
                == "Museu Oscar Niemeyer"
        )
        #expect(
            PlaceDisplayNameResolver.displayName(nickname: "", name: "Parque Barigui")
                == "Parque Barigui"
        )
    }
}
