import Testing
@testable import ZanzarProject

@Suite("Generated avatars")
struct AvatarGeneratedTests {
    @Test("the same seed always gives the same avatar")
    func isDeterministic() {
        #expect(Avatar.generated(seed: "centro-0") == Avatar.generated(seed: "centro-0"))
    }

    @Test("different seeds give different faces")
    func varies() {
        let faces = Set((0..<30).map { Avatar.generated(seed: "roteiro-\($0)") })

        #expect(faces.count > 15)
    }

    @Test("the background is one of the three colors of the design")
    func backgroundsFromTheDesign() {
        let backgrounds = Set((0..<100).map { Avatar.generated(seed: "bg-\($0)").background })

        #expect(backgrounds == ["#FFE0A2", "#463AC8", "#FE2963"])
    }

    @Test("every layer stays inside what the backend accepts")
    func staysInRange() {
        for index in 0..<200 {
            let avatar = Avatar.generated(seed: "seed-\(index)")

            #expect((1...AvatarCatalog.skinCount).contains(avatar.skin))
            #expect((1...AvatarCatalog.eyeColors.count).contains(avatar.eyes))
            #expect((1...AvatarCatalog.eyebrowColors.count).contains(avatar.eyebrow))
            #expect((0...AvatarCatalog.eyelashColors.count).contains(avatar.eyelash))
            #expect((0...AvatarCatalog.hairCount).contains(avatar.hair))
            #expect(avatar.background.hasPrefix("#") && avatar.background.count == 7)
        }
    }
}

@MainActor
@Suite("ItineraryCompletersView faces")
struct ItineraryCompletersFacesTests {
    private static let real = Avatar(skin: 2, eyes: 1, eyebrow: 1, eyelash: 0, hair: 1, background: "#FFE0A2")

    @Test("nobody completed it: no faces")
    func nobody() {
        #expect(ItineraryCompletersView.faces(avatars: [], completedCount: 0, seed: "a").isEmpty)
    }

    @Test("people with no avatar sent get made-up ones, up to three")
    func standIns() {
        #expect(ItineraryCompletersView.faces(avatars: [], completedCount: 2, seed: "a").count == 2)
        #expect(ItineraryCompletersView.faces(avatars: [], completedCount: 40, seed: "a").count == 3)
    }

    @Test("real avatars come first and only the missing ones are made up")
    func mixed() {
        let faces = ItineraryCompletersView.faces(avatars: [Self.real], completedCount: 40, seed: "a")

        #expect(faces.count == 3)
        #expect(faces[0] == Self.real)
        #expect(faces[1] != faces[2])
    }

    @Test("stand-ins are the same on every draw")
    func stable() {
        let first = ItineraryCompletersView.faces(avatars: [], completedCount: 3, seed: "centro")
        let second = ItineraryCompletersView.faces(avatars: [], completedCount: 3, seed: "centro")

        #expect(first == second)
    }
}
