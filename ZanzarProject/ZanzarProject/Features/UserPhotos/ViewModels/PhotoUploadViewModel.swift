import CoreGraphics
import Foundation
import Observation

/// Sending one photo of a place: terms check, picking, editing (crop, zoom, turn), on-device checks (sensitive content,
/// faces) on the edited photo, preview, upload.
@Observable
final class PhotoUploadViewModel {
    enum Step: Equatable {
        case checkingTerms
        case needsTerms
        case choosing
        case preparing
        /// The user crops, zooms and turns the picked photo.
        case editing
        /// The edit is being applied and the on-device checks are running on the result.
        case analyzing
        /// Faces in the foreground: the user picks another photo or has them pixelated.
        case faceWarning
        case preview
        case uploading
        case sent(UserPhotoStatus)
        case failed(PhotoUploadError)
    }

    let placeID: String
    let placeName: String
    /// Sent from a place where the user already checked in: the server marks it as verified.
    let fromCheckIn: Bool

    private(set) var step: Step = .checkingTerms
    var showsAuthorName = true
    /// The picked photo as decoded, before any edit or pixelation. The editor shows it and "edit again" starts from it.
    private(set) var original: CGImage?
    /// The photo that will be sent, after the edit and any pixelation.
    private(set) var image: CGImage?
    private(set) var hasBlurredFaces = false
    private var prominentFaces: [CGRect] = []

    private let service: UserPhotosServicing
    private let processing: PhotoProcessing
    private let sensitiveContent: SensitiveContentChecking
    private let userIDProvider: @Sendable () -> String?
    private let isOnline: @MainActor () -> Bool

    init(
        placeID: String,
        placeName: String,
        fromCheckIn: Bool,
        service: UserPhotosServicing = UserPhotosService(),
        processing: PhotoProcessing = DevicePhotoProcessing(),
        sensitiveContent: SensitiveContentChecking = SensitiveContentChecker(),
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.userID },
        isOnline: @escaping @MainActor () -> Bool = { PlaceMediaAccessPolicy.shared.isOnline }
    ) {
        self.placeID = placeID
        self.placeName = placeName
        self.fromCheckIn = fromCheckIn
        self.service = service
        self.processing = processing
        self.sensitiveContent = sensitiveContent
        self.userIDProvider = userIDProvider
        self.isOnline = isOnline
    }

    var faceCount: Int { prominentFaces.count }

    /// Shows the terms first when the user has not accepted the current version (or has no declared adult age).
    func start() async {
        guard let userID = userIDProvider() else {
            step = .failed(.termsRequired)
            return
        }
        step = .checkingTerms
        do {
            let status = try await service.fetchTermsStatus(userID: userID)
            step = status.canUpload ? .choosing : .needsTerms
        } catch {
            step = .failed(PhotoUploadError(error))
        }
    }

    func termsAccepted() {
        step = .choosing
    }

    /// Decodes the picked file and opens the editor. The on-device checks wait for the edited photo.
    func pick(_ data: Data) async {
        step = .preparing
        hasBlurredFaces = false
        image = nil
        original = nil
        prominentFaces = []
        do {
            original = try await processing.downsample(data)
            step = .editing
        } catch PhotoPreparer.Failure.tooLarge {
            step = .failed(.tooLarge)
        } catch {
            step = .failed(.unreadable)
        }
    }

    /// Applies what the user did in the editor, then runs the on-device checks (sensitive content, faces) on the
    /// result: a crop can make a face prominent, so the checks must see the photo that will be sent.
    func applyEdit(_ edit: PhotoEdit) async {
        guard let original else { return }
        step = .analyzing
        hasBlurredFaces = false
        image = nil
        prominentFaces = []
        guard let edited = await processing.edit(original, edit) else {
            step = .failed(.unreadable)
            return
        }
        if await sensitiveContent.isSensitive(edited) == true {
            AppLog.userPhotos.info("Edited photo refused by on-device sensitive content analysis")
            step = .failed(.sensitiveContent)
            return
        }
        image = edited
        prominentFaces = FacePolicy.prominentFaces(in: await processing.faces(in: edited))
        step = prominentFaces.isEmpty ? .preview : .faceWarning
    }

    func cancelEditing() {
        chooseAnother()
    }

    /// Back to the editor from the preview or the face warning, starting from the original photo.
    func editAgain() {
        guard original != nil, step == .preview || step == .faceWarning else { return }
        image = nil
        prominentFaces = []
        hasBlurredFaces = false
        step = .editing
    }

    func chooseAnother() {
        image = nil
        original = nil
        prominentFaces = []
        hasBlurredFaces = false
        step = .choosing
    }

    /// Pixelates the faces and shows the result, so the user checks it before sending.
    func blurFaces() async {
        guard let image else { return }
        step = .preparing
        guard let blurred = await processing.blur(prominentFaces, in: image) else {
            step = .failed(.unreadable)
            return
        }
        self.image = blurred
        hasBlurredFaces = true
        prominentFaces = []
        step = .preview
    }

    func send() async {
        guard let image else { return }
        guard isOnline() else {
            step = .failed(.offline)
            return
        }
        step = .uploading
        do {
            let jpeg = try await processing.encode(image)
            let prepared = PreparedPhoto(jpeg: jpeg, width: image.width, height: image.height, prominentFaces: [])
            let photo = try await service.upload(
                prepared,
                placeID: placeID,
                fromCheckIn: fromCheckIn,
                showsAuthorName: showsAuthorName
            )
            step = .sent(photo.status)
        } catch {
            step = .failed(PhotoUploadError(error))
        }
    }

    /// After a failure: back to the preview when the same photo can be sent again, else to choosing.
    func recover() {
        guard case .failed(let error) = step else { return }
        if error == .termsRequired {
            step = .needsTerms
        } else if error.isRetryable, image != nil {
            step = .preview
        } else {
            chooseAnother()
        }
    }
}
