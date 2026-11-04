import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import ZanzarProject

@Suite("User photo mapping, mixing and preparation")
struct UserPhotosMappingTests {
    private func userPhoto(_ id: String, status: UserPhotoStatus, verified: Bool, own: Bool = false) -> PlacePhoto {
        PlacePhoto(
            url: URL(string: "https://x/\(id).jpg")!,
            credit: nil,
            userAttribution: UserPhotoAttribution(
                photoID: id, authorName: nil, isVerifiedCheckIn: verified, isOwn: own, status: status
            )
        )
    }

    @Test("curated first, then own photos under review, then verified, then unverified, at most five")
    func mixingOrder() {
        let curated = ["1", "2"].map { PlacePhoto(url: URL(string: "https://c/\($0).jpg")!, credit: nil) }
        let user = [
            userPhoto("unverified", status: .approved, verified: false),
            userPhoto("verified", status: .approved, verified: true),
            userPhoto("mine", status: .pending, verified: false, own: true),
            userPhoto("extra", status: .approved, verified: false)
        ]
        let mixed = PlacePhotoMixer.mix(curated: curated, user: user, limit: 5)
        #expect(mixed.map(\.url.lastPathComponent) == ["1.jpg", "2.jpg", "mine.jpg", "verified.jpg", "unverified.jpg"])
    }

    @Test("the place list never shows someone else's unapproved photo or a rejected one")
    func decodeOnlyShowable() throws {
        func entry(_ id: String, _ status: String, url: String, own: Bool, author: String? = nil) -> String {
            let name = author.map { "\"\($0)\"" } ?? "null"
            return #"{"id":"\#(id)","status":"\#(status)","url":"\#(url)","thumbnailUrl":null,"#
                + #""isVerifiedCheckIn":true,"authorName":\#(name),"isOwn":\#(own)}"#
        }
        let entries = [
            entry("1", "approved", url: "https://s/1.jpg", own: false, author: "ana"),
            entry("2", "pending", url: "https://s/2.jpg", own: false),
            entry("3", "needs_review", url: "https://s/3.jpg", own: true),
            entry("4", "rejected", url: "https://s/4.jpg", own: true),
            entry("5", "approved", url: "ftp://s/5.jpg", own: false)
        ]
        let json = #"{"photos":["# + entries.joined(separator: ",") + "]}"
        let response = try JSONDecoder().decode(PlaceUserPhotoListAPIResponse.self, from: Data(json.utf8))
        let photos = response.placePhotos
        #expect(photos.compactMap(\.userAttribution?.photoID) == ["1", "3"])
        #expect(photos.first?.userAttribution?.authorName == "ana")
    }

    @Test("server refusal codes map to what the screen explains", arguments: [
        ("duplicate_photo", 409, PhotoUploadError.duplicate),
        ("terms_required", 403, .termsRequired),
        ("age_declaration_required", 403, .termsRequired),
        ("image_too_large", 413, .tooLarge),
        ("unsupported_format", 415, .unsupportedFormat),
        ("image_too_small", 422, .unreadable),
        ("invalid_check_in", 422, .noCheckIn),
        ("photo_uploads_disabled", 503, .unavailable)
    ])
    func errorMapping(code: String, status: Int, expected: PhotoUploadError) {
        #expect(PhotoUploadError(APIError.rejected(status, code: code, message: nil)) == expected)
    }

    @Test("a coded error body decodes into APIError.rejected")
    func apiErrorDecodesCode() {
        let body = Data(#"{"success":false,"message":"This photo was already sent","code":"duplicate_photo"}"#.utf8)
        guard case .rejected(409, "duplicate_photo", _) = APIError.from(data: body, statusCode: 409) else {
            Issue.record("Expected a coded rejection")
            return
        }
    }

    @Test("decision reason codes map to plain-language keys")
    func decisionReasons() {
        #expect(UserPhotoDecisionReason(code: "face_prominent").messageKey == "userPhotos.decisionReason.faceProminent")
        #expect(UserPhotoDecisionReason(code: "copyright") == .watermark)
        #expect(UserPhotoDecisionReason(code: "brand_new_code").messageKey == "userPhotos.decisionReason.other")
    }

    @Test("preparing a photo downsizes it to 2048 px and removes EXIF and GPS")
    func preparationStripsMetadata() async throws {
        let source = try Self.jpegWithLocation(width: 3000, height: 2000)
        #expect(PhotoPreparer.containsIdentifyingMetadata(source))

        let image = try await PhotoPreparer.downsample(source)
        let jpeg = try await PhotoPreparer.encode(image)

        #expect(max(image.width, image.height) == 2048)
        #expect(!PhotoPreparer.containsIdentifyingMetadata(jpeg))
    }

    @Test("files over the limit are refused before decoding")
    func tooLargeInput() async {
        await #expect(throws: PhotoPreparer.Failure.tooLarge) {
            try await PhotoPreparer.downsample(Data(count: PhotoPreparer.maximumInputBytes + 1))
        }
    }

    /// A JPEG carrying EXIF (camera model, date) and GPS, like one straight from an iPhone.
    private static func jpegWithLocation(width: Int, height: Int) throws -> Data {
        let context = try #require(CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ))
        context.setFillColor(CGColor(red: 0.8, green: 0.3, blue: 0.2, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width / 2, height: height))
        let image = try #require(context.makeImage())
        let output = NSMutableData()
        let type = UTType.jpeg.identifier as CFString
        let destination = try #require(CGImageDestinationCreateWithData(output, type, 1, nil))
        let properties: [CFString: Any] = [
            kCGImagePropertyGPSDictionary: [kCGImagePropertyGPSLatitude: 25.43, kCGImagePropertyGPSLatitudeRef: "S",
                                            kCGImagePropertyGPSLongitude: 49.27, kCGImagePropertyGPSLongitudeRef: "W"],
            kCGImagePropertyExifDictionary: [kCGImagePropertyExifDateTimeOriginal: "2026:11:03 12:00:00"],
            kCGImagePropertyTIFFDictionary: [kCGImagePropertyTIFFModel: "iPhone 17 Pro"]
        ]
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        return output as Data
    }
}
