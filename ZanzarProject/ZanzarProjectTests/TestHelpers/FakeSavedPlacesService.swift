import Foundation
@testable import ZanzarProject

/// In-memory saved places: remembers what it was asked to save or remove, and can be made to fail.
@MainActor
final class FakeSavedPlacesService: SavedPlacesServicing {
    private(set) var savedIDs: Set<String>
    private(set) var saveCalls: [String] = []
    private(set) var removeCalls: [String] = []
    private var failure: Error?
    var removeFailure: Error?

    init(savedIDs: Set<String> = [], failure: Error? = nil) {
        self.savedIDs = savedIDs
        self.failure = failure
    }

    var listed: [SavedPlace] = []

    func fetchSavedPlaces(userID: String) async throws -> [SavedPlace] {
        if let failure { throw failure }
        if !listed.isEmpty { return listed.filter { savedIDs.contains($0.placeID) } }
        return savedIDs.sorted().map { SavedPlace(placeID: $0, name: nil, imageURL: nil, savedAt: .distantPast) }
    }

    func savedPlaceIDs(userID: String) async throws -> Set<String> {
        if let failure { throw failure }
        return savedIDs
    }

    func save(placeID: String, userID: String) async throws {
        saveCalls.append(placeID)
        if let failure { throw failure }
        savedIDs.insert(placeID)
    }

    func remove(placeID: String, userID: String) async throws {
        removeCalls.append(placeID)
        if let failure { throw failure }
        if let removeFailure { throw removeFailure }
        savedIDs.remove(placeID)
    }
}
