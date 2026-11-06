import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("UserPhotosService")
struct UserPhotosServiceTests {
    @Test("upload sends the JPEG bytes with the options as query items")
    func uploadRequest() async throws {
        let client = RecordingClient()
        let service = UserPhotosService(client: client)
        let photo = PreparedPhoto(jpeg: Data([0xFF, 0xD8, 0xFF, 0x01]), width: 10, height: 10, prominentFaces: [])

        let result = try await service.upload(photo, placeID: "ChIJ-x", fromCheckIn: true, showsAuthorName: false)

        #expect(result.status == .pending)
        let call = try #require(client.lastUpload)
        #expect(call.path == "places/ChIJ-x/photos")
        #expect(call.contentType == "image/jpeg")
        #expect(call.data == photo.jpeg)
        #expect(call.queryItems.contains(URLQueryItem(name: "fromCheckIn", value: "true")))
        #expect(call.queryItems.contains(URLQueryItem(name: "showAuthorName", value: "false")))
    }

    @Test("the birth date is sent as a calendar day")
    func dayString() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        let date = calendar.date(from: DateComponents(year: 1990, month: 5, day: 7, hour: 23))!
        #expect(UserPhotosService.dayString(date, calendar: calendar) == "1990-05-07")
    }

    @Test("a server refusal becomes a PhotoUploadError")
    func uploadErrorMapping() async {
        let client = RecordingClient()
        client.uploadError = APIError.rejected(409, code: "duplicate_photo", message: "x")
        let service = UserPhotosService(client: client)
        await #expect(throws: PhotoUploadError.duplicate) {
            let photo = PreparedPhoto(jpeg: Data([1]), width: 1, height: 1, prominentFaces: [])
            _ = try await service.upload(photo, placeID: "p", fromCheckIn: false, showsAuthorName: true)
        }
    }
}

private nonisolated final class RecordingClient: NetworkClient, @unchecked Sendable {
    struct Upload {
        let path: String
        let queryItems: [URLQueryItem]
        let data: Data
        let contentType: String
    }

    var lastUpload: Upload?
    var uploadError: Error?

    func get<Response: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> Response {
        throw APIError.invalidRequest
    }

    func send<Body: Encodable, Response: Decodable>(
        path: String,
        method: HTTPMethod,
        body: Body
    ) async throws -> Response {
        throw APIError.invalidRequest
    }

    func sendWithoutResponse(path: String, method: HTTPMethod) async throws {}

    func upload<Response: Decodable>(
        path: String,
        queryItems: [URLQueryItem],
        data: Data,
        contentType: String
    ) async throws -> Response {
        lastUpload = Upload(path: path, queryItems: queryItems, data: data, contentType: contentType)
        if let uploadError { throw uploadError }
        let json = """
        {"id":"1","placeId":"ChIJ-x","placeName":"Bar","status":"pending","isVerifiedCheckIn":true,
         "showAuthorName":false,"url":null,"thumbnailUrl":null,"width":10,"height":10,"decisionReason":null,
         "createdAt":"2026-11-04T12:00:00.000Z","decidedAt":null}
        """
        return try JSONDecoder().decode(Response.self, from: Data(json.utf8))
    }
}
