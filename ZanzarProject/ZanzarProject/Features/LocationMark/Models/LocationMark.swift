import Foundation

struct LocationMark: Identifiable, Hashable, Sendable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let capturedAt: Date
}
