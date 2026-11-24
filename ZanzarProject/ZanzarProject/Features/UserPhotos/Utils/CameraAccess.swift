import AVFoundation
import UIKit

/// Whether the camera can be used, and asking for it. The photo library needs no permission: `PhotosPicker`
/// runs outside the app and hands over only the chosen photo.
nonisolated enum CameraAccess: Equatable, Sendable {
    case available
    case notDetermined
    case denied
    /// Blocked by Screen Time or a device management profile; the user cannot change it.
    case restricted
    /// No camera (e.g. the Simulator).
    case unavailable

    @MainActor
    static var current: CameraAccess {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return .unavailable }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return .available
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        @unknown default: return .denied
        }
    }

    static func request() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }
}
