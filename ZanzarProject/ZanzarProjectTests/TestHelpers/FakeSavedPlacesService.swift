import Foundation
@testable import ZanzarProject

/// In-memory saved places: remembers what it was asked to save or remove, and can be made to fail.
@MainActor
final class FakeSavedPlacesService: SavedPlacesServicing {
    private(set) var savedIDs: Set<String>
    private(set) var saveCalls: [String] = []
    private(set) var removeCalls: [String] = []
    private var failure: Error?

    init(savedIDs: Set<String> = [], failure: Error? = nil) {
        self.savedIDs = savedIDs
        self.failure = failure
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
        savedIDs.remove(placeID)
    }
}
