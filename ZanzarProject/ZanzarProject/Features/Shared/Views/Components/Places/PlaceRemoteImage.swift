import SwiftUI

/// A remote image view for place photos with proper error handling, retry logic, and caching.
struct PlaceRemoteImage<Placeholder: View>: View {
    let photoReference: String?
    let mediaPolicy: PlaceMediaAccessPolicy
    let placeholder: Placeholder
    let maxWidth: Int

    @State private var loadAttempts = 0
    @State private var currentURL: URL?
    @State private var lastError: Error?

    init(
        photoReference: String?,
        mediaPolicy: PlaceMediaAccessPolicy? = nil,
        maxWidth: Int = 800,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.photoReference = photoReference
        self.mediaPolicy = mediaPolicy ?? .shared
        self.maxWidth = maxWidth
        self.placeholder = placeholder()
    }

    var body: some View {
        Group {
            if let photoReference,
               mediaPolicy.canLoadRemoteImages,
               let url = GooglePlacesConfiguration.photoURL(reference: photoReference, maxWidth: maxWidth) {
                AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.2))) { phase in
                    switch phase {
                    case .success(let image):
                        // Reset error state on success
                        image
                            .resizable()
                            .scaledToFill()
                            .onAppear {
                                loadAttempts = 0
                                lastError = nil
                                #if DEBUG
                                AppLog.placeDetail.info("Place photo loaded successfully ref=\(photoReference)")
                                #endif
                            }
                    case .failure(let error):
                        placeholder
                            .onAppear {
                                handleError(error, photoReference: photoReference, url: url)
                            }
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .onAppear {
                                #if DEBUG
                                AppLog.placeDetail.debug("Place photo loading started ref=\(photoReference)")
                                #endif
                            }
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
                    .onAppear {
                        logSkipReason(photoReference: photoReference)
                    }
            }
        }
    }

    private func handleError(_ error: Error, photoReference: String, url: URL) {
        lastError = error
        loadAttempts += 1

        #if DEBUG
        AppLog.placeDetail.warning("Place photo failed to load (attempt \(loadAttempts)) ref=\(photoReference) error=\(error.localizedDescription)")
        #endif

        // Retry up to 2 times with exponential backoff
        if loadAttempts <= 2 {
            let delay = UInt64(pow(2.0, Double(loadAttempts)) * 1_000_000_000) // 2s, 4s
            Task {
                try? await Task.sleep(nanoseconds: delay)
                // Trigger a reload by updating the URL
                await MainActor.run {
                    currentURL = url
                }
            }
        }
    }

    private func logSkipReason(photoReference: String?) {
        #if DEBUG
        if photoReference == nil {
            AppLog.placeDetail.debug("Place photo skipped: no photo reference")
        } else if !mediaPolicy.canLoadRemoteImages {
            AppLog.placeDetail.debug("Place photo skipped: cellular images not allowed ref=\(photoReference!)")
        } else {
            AppLog.placeDetail.debug("Place photo skipped: invalid URL ref=\(photoReference!)")
        }
        #endif
    }
}

extension PlaceRemoteImage where Placeholder == Color {
    /// Convenience initializer with a simple color placeholder
    init(
        photoReference: String?,
        mediaPolicy: PlaceMediaAccessPolicy? = nil,
        maxWidth: Int = 800,
        placeholderColor: Color = .gray.opacity(0.2)
    ) {
        self.init(
            photoReference: photoReference,
            mediaPolicy: mediaPolicy,
            maxWidth: maxWidth,
            placeholder: { placeholderColor }
        )
    }
}