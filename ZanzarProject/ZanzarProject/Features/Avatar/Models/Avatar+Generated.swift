import Foundation

extension Avatar {
    private static let generatedBackgrounds = ["#FFE0A2", "#463AC8", "#FE2963"]

    static func generated(seed: String) -> Avatar {
        var state = fnv1a(seed)
        func next(_ count: Int) -> Int {
            // xorshift: enough to spread the options, and the same on every launch (unlike `hashValue`).
            state ^= state << 13
            state ^= state >> 7
            state ^= state << 17
            return Int(state % UInt64(count))
        }
        return Avatar(
            skin: 1 + next(AvatarCatalog.skinCount),
            eyes: 1 + next(AvatarCatalog.eyeColors.count),
            eyebrow: 1 + next(AvatarCatalog.eyebrowColors.count),
            eyelash: next(AvatarCatalog.eyelashColors.count + 1),
            hair: next(AvatarCatalog.hairCount + 1),
            background: generatedBackgrounds[next(generatedBackgrounds.count)]
        )
    }

    private static func fnv1a(_ text: String) -> UInt64 {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return hash == 0 ? 1 : hash
    }
}
