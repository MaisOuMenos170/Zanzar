import Foundation
import os

/// wrappes over os.Logger
/// 🔵 info, 🟡 warning, 🔴 error.
///
/// doesn't print emails, passwords or tokens in a message
/// log ids, counts and status codes
enum AppLog: String {
    case network
    case auth
    case login
    case signUp
    case map
    case placeDetail
    case ratingPrompt
    case profile
    case itinerary

    private static let subsystem = Bundle.main.bundleIdentifier ?? "ZanzarProject"

    private var logger: Logger {
        Logger(subsystem: Self.subsystem, category: rawValue)
    }

    func info(
        _ message: String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        let text = format("🔵", message, file, function, line)
        logger.info("\(text, privacy: .public)")
    }

    func warning(
        _ message: String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        let text = format("🟡", message, file, function, line)
        logger.warning("\(text, privacy: .public)")
    }

    /// Also logs the full error (type, reflected detail, NSError domain/code) so a failure can
    /// be traced. Cancellations are not errors and are skipped.
    func error(
        _ message: String,
        error: Error? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        if let error, error is CancellationError || (error as? URLError)?.code == .cancelled {
            return
        }
        var details: [String] = []
        if let error {
            let nsError = error as NSError
            details.append("type=\(type(of: error))")
            details.append("detail=\(String(reflecting: error))")
            details.append("domain=\(nsError.domain) code=\(nsError.code)")
        }
        let text = format("🔴", message, file, function, line, details: details)
        // `.notice` instead of `.error`: Xcode paints `.error` lines with a yellow background,
        // which gets confused with UI warnings. Notice is still persisted on device.
        logger.notice("\(text, privacy: .public)")
    }

    private func format(
        _ emoji: String,
        _ message: String,
        _ file: String,
        _ function: String,
        _ line: Int,
        details: [String] = []
    ) -> String {
        let fileName = file.split(separator: "/").last.map(String.init) ?? file
        let location = "\(fileName):\(line) \(function)"
        return "\(emoji) [\(rawValue)] \(location) | " + ([message] + details).joined(separator: " | ")
    }
}
