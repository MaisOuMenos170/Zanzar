import Foundation

enum APIError: Error, Sendable {
    case httpStatus(Int, message: String?)
    case decodingFailed
    case invalidResponse
    case invalidRequest

    static func from(data: Data, statusCode: Int) -> APIError {
        if let payload = try? JSONDecoder().decode(APIErrorPayload.self, from: data) {
            if let message = payload.message, !message.isEmpty {
                return .httpStatus(statusCode, message: message)
            }
            if let errors = payload.errors, !errors.isEmpty {
                return .httpStatus(statusCode, message: errors)
            }
        }
        return .httpStatus(statusCode, message: nil)
    }
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .httpStatus(_, let message):
            message
        case .decodingFailed, .invalidResponse, .invalidRequest:
            nil
        }
    }
}

// Used by `String(reflecting:)` in logs: status only, never the server-provided message,
// which can echo submitted login/registration data.
extension APIError: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .httpStatus(let status, _):
            "APIError.httpStatus(\(status))"
        case .decodingFailed:
            "APIError.decodingFailed"
        case .invalidResponse:
            "APIError.invalidResponse"
        case .invalidRequest:
            "APIError.invalidRequest"
        }
    }
}

private nonisolated struct APIErrorPayload: Decodable {
    let success: Bool?
    let message: String?
    let errors: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decodeIfPresent(Bool.self, forKey: .success)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        if let errorsString = try? container.decode(String.self, forKey: .errors) {
            errors = errorsString
        } else if container.contains(.errors) {
            errors = String(describing: try container.decode(JSONValue.self, forKey: .errors))
        } else {
            errors = nil
        }
    }

    private enum CodingKeys: String, CodingKey {
        case success
        case message
        case errors
    }
}

private nonisolated enum JSONValue: Decodable, CustomStringConvertible {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    var description: String {
        switch self {
        case .string(let value):
            value
        case .number(let value):
            String(value)
        case .bool(let value):
            String(value)
        case .object(let value):
            value.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        case .array(let value):
            value.map(\.description).joined(separator: ", ")
        case .null:
            ""
        }
    }
}
