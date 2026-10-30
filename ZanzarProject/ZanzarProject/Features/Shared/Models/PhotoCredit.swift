import Foundation

/// Who took a place photo and under which licence. CC BY and CC BY-SA require showing it.
nonisolated struct PhotoCredit: Hashable, Sendable {
    let author: String
    let license: String
    /// The page of the photo at its source, such as the Wikimedia Commons file page.
    let sourceURL: URL
}
