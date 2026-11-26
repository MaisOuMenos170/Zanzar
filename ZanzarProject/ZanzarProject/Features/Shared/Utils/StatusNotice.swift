import Foundation

/// A line the app shows when a review finished while the user was away: the text and which toast carries it.
/// "Not approved" is bad news and must not wear the green check that good news gets.
struct StatusNotice: Equatable, Sendable {
    let message: String
    let style: ToastStyle

    static func positive(_ message: String) -> StatusNotice { StatusNotice(message: message, style: .positive) }
    static func negative(_ message: String) -> StatusNotice { StatusNotice(message: message, style: .negative) }
}
