import Foundation
import Observation

/// When the app opens, tells the user about photos whose review finished since they last looked.
@Observable
final class PhotoStatusNoticeViewModel {
    private let service: UserPhotosServicing
    private let store: UserPhotoStatusStoring
    private let userIDProvider: @Sendable () -> String?
    private let now: () -> Date

    init(
        service: UserPhotosServicing = UserPhotosService(),
        store: UserPhotoStatusStoring = UserDefaultsUserPhotoStatusStore(),
        userIDProvider: @escaping @Sendable () -> String? = { AuthTokenStore.shared.userID },
        now: @escaping () -> Date = { Date() }
    ) {
        self.service = service
        self.store = store
        self.userIDProvider = userIDProvider
        self.now = now
    }

    /// The message to show, or `nil` when nothing changed. The first run only records what is there.
    func checkForChanges() async -> String? {
        guard let userID = userIDProvider(),
              let photos = try? await service.fetchMyPhotos(userID: userID) else { return nil }
        let previous = store.lastSeenStatuses()
        let lastCheck = store.lastCheckedAt()
        let current = Dictionary(uniqueKeysWithValues: photos.map { ($0.id, $0.status.rawValue) })
        store.save(current, checkedAt: now())
        // The very first check only records what is there.
        guard let lastCheck else { return nil }

        let changed = photos.filter { photo in
            guard !photo.status.isUnderReview else { return false }
            if let before = previous[photo.id] {
                return before != photo.status.rawValue
            }
            // Sent and decided since the last look (e.g. sent in this session, reviewed while the app was closed).
            return (photo.decidedAt ?? .distantPast) > lastCheck
        }
        let published = changed.filter { $0.status == .approved }.count
        let refused = changed.count - published
        switch (published, refused) {
        case (0, 0): return nil
        case (_, 0): return L10n.string("userPhotos.notice.published", published)
        case (0, _): return L10n.string("userPhotos.notice.notApproved", refused)
        default: return L10n.string("userPhotos.notice.mixed", published, refused)
        }
    }
}
