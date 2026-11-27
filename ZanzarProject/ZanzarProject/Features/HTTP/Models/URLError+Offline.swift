import Foundation

nonisolated extension URLError {
    /// The network is unreachable right now (no connection, dropped, timed out, host down): the same request may
    /// well work later, so the work is worth keeping instead of failing it.
    var isOffline: Bool {
        Self.offlineCodes.contains(code)
    }

    private static let offlineCodes: Set<URLError.Code> = [
        .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost
    ]
}

nonisolated extension Error {
    /// `true` for a `URLError` that `isOffline` describes.
    var isOffline: Bool {
        (self as? URLError)?.isOffline == true
    }
}
