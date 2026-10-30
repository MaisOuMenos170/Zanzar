import SwiftUI

/// A remote image view for place photos with proper error handling, retry logic, and caching.
struct PlaceRemoteImage<Placeholder: View>: View {
    let photoURL: URL?
    let mediaPolicy: PlaceMediaAccessPolicy
    let placeholder: Placeholder

    /// Failed loads so far. It is the `AsyncImage` identity: `AsyncImage` only fetches again when its URL
    /// or its identity changes, and a retry uses the same URL.
    @State private var failedAttempts = 0

    init(
        photoURL: URL?,
        mediaPolicy: PlaceMediaAccessPolicy? = nil,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.photoURL = photoURL
        self.mediaPolicy = mediaPolicy ?? .shared
        self.placeholder = placeholder()
    }

    var body: some View {
        Group {
            if let url = photoURL, mediaPolicy.canLoadRemoteImages {
                AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.2))) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .onAppear {
                                #if DEBUG
                                AppLog.placeDetail.info("Place photo loaded successfully url=\(url.lastPathComponent)")
                                #endif
                            }
                    case .failure(let error):
                        placeholder
                            // Cancelled with the view, so leaving the screen ends the wait.
                            .task {
                                await retryAfterFailure(error, url: url)
                            }
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    @unknown default:
                        placeholder
                    }
                }
                .id(failedAttempts)
                .onChange(of: photoURL) {
                    failedAttempts = 0
                }
            } else {
                placeholder
                    .onAppear {
                        logSkipReason()
                    }
            }
        }
    }

    private func retryAfterFailure(_ error: Error, url: URL) async {
        let failed = failedAttempts + 1

        #if DEBUG
        AppLog.placeDetail.warning("Place photo failed to load (attempt \(failed)) url=\(url.lastPathComponent) error=\(error.localizedDescription)")
        #endif

        guard let delay = PhotoRetryPolicy.delay(afterFailedAttempts: failed) else { return }
        do {
            try await Task.sleep(for: delay)
        } catch {
            return
        }
        failedAttempts = failed
    }

    private func logSkipReason() {
        #if DEBUG
        if photoURL == nil {
            AppLog.placeDetail.info("Place photo skipped: no photo URL")
        } else {
            AppLog.placeDetail.info("Place photo skipped: remote images are not allowed on this network")
        }
        #endif
    }
}

extension PlaceRemoteImage where Placeholder == Color {
    /// Convenience initializer with a simple color placeholder
    init(
        photoURL: URL?,
        mediaPolicy: PlaceMediaAccessPolicy? = nil,
        placeholderColor: Color = .gray.opacity(0.2)
    ) {
        self.init(
            photoURL: photoURL,
            mediaPolicy: mediaPolicy,
            placeholder: { placeholderColor }
        )
    }
}
