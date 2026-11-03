import CoreLocation
import Foundation

/// A place Apple Maps returned for a search, reduced to what the matcher compares.
nonisolated struct ApplePlaceCandidate: Hashable, Sendable {
    let name: String
    let latitude: Double
    let longitude: Double
}

/// Picks which Apple Maps result is our place. Apple's place card shows its own photos and reviews, so a wrong
/// match would show another business: a result counts only when it is close and shares a distinctive word
/// with our name.
nonisolated enum ApplePlaceMatcher {
    /// Parks and woods are large, and Apple pins them far from our point; anything else must be close.
    static func maximumDistanceMeters(for category: ZanzarPlaceCategory) -> Double {
        category == .park ? 700 : 300
    }

    /// The text sent to Apple's search: the catalog name without the extras after " | " or " - "
    /// ("Museu Paranaense | MUPA", "Arcádia - Sebo & Café - Vinis, Livros"), which Apple does not know.
    static func searchQuery(for name: String) -> String {
        var query = name
        for separator in [" | ", " - "] {
            if let range = query.range(of: separator) {
                query = String(query[..<range.lowerBound])
            }
        }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? name : trimmed
    }

    /// The index of the closest candidate that matches `names`, or `nil` when none does.
    static func bestMatchIndex(
        names: [String],
        latitude: Double,
        longitude: Double,
        category: ZanzarPlaceCategory,
        candidates: [ApplePlaceCandidate]
    ) -> Int? {
        let place = CLLocation(latitude: latitude, longitude: longitude)
        let maximumDistance = maximumDistanceMeters(for: category)
        let placeWords = Set(names.flatMap(distinctiveWords))

        return candidates.indices
            .map { index in
                let candidate = candidates[index]
                let distance = place.distance(
                    from: CLLocation(latitude: candidate.latitude, longitude: candidate.longitude)
                )
                return (index: index, distance: distance, words: distinctiveWords(in: candidate.name))
            }
            .filter { $0.distance <= maximumDistance && !$0.words.isDisjoint(with: placeWords) }
            .min { $0.distance < $1.distance }?
            .index
    }

    /// Words that identify a place: folded to lowercase ASCII, at least three letters, and not a word that
    /// half the catalog shares ("museu", "bar", "curitiba"...).
    static func distinctiveWords(in name: String) -> Set<String> {
        let folded = name.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: Locale(identifier: "pt_BR")
        )
        let words = folded
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 && !genericWords.contains($0) }
        return Set(words)
    }

    private static let genericWords: Set<String> = [
        "bar", "bares", "cafe", "coffee", "restaurante", "restaurant", "lanches", "pizzaria", "cantina",
        "museu", "museum", "memorial", "parque", "park", "bosque", "praca", "square", "rua", "avenida",
        "edificio", "curitiba", "parana", "comida", "the", "dos", "das", "para", "com", "and"
    ]
}
