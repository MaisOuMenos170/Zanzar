import Foundation

nonisolated struct ProfileCheckInsPage: Hashable, Sendable {
    let checkIns: [ProfileCheckIn]
    let nextCursor: String?
}
