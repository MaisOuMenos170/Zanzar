import Foundation

/// Where the passport intro animation is: untouched, the hand holding the stamp over the page, or stamped.
enum PassportStampStage: Equatable, Sendable {
    case idle
    case handOver
    case stamped
}
