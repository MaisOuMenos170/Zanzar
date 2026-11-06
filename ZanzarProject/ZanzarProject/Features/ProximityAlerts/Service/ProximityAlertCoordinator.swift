import Foundation

/// Ties the pieces together: keeps the monitored regions in step with the places around the user and the roteiro
/// they follow, and turns "the user came close to X" into a notification, if the policy allows it.
///
/// Regions are chosen while the app is in use. When a region fires, possibly in a relaunched background process,
/// the decision uses the places saved at that time, so nothing here depends on the network.
final class ProximityAlertCoordinator {
    private let monitor: ProximityMonitoring
    private let notifier: ProximityNotifying
    private let store: ProximityAlertStoring
    private let policy: ProximityAlertPolicy
    private let now: () -> Date

    private var places: [MapPlace] = []
    private var user: UserCoordinate?
    private var itinerary: ActiveItinerary?
    private var listening: Task<Void, Never>?

    init(
        monitor: ProximityMonitoring,
        notifier: ProximityNotifying,
        store: ProximityAlertStoring,
        policy: ProximityAlertPolicy = ProximityAlertPolicy(),
        now: @escaping () -> Date = { Date() }
    ) {
        self.monitor = monitor
        self.notifier = notifier
        self.store = store
        self.policy = policy
        self.now = now
    }

    /// Starts listening to the monitor. Call it as early as the app launches, also for a background relaunch.
    func start() {
        guard listening == nil else { return }
        let entries = monitor.entries
        let monitor = monitor
        listening = Task { [weak self] in
            await monitor.resume()
            for await placeID in entries {
                await self?.handleEntry(placeID: placeID)
            }
        }
    }

    func update(places: [MapPlace], user: UserCoordinate?) async {
        self.places = places
        self.user = user
        await resync()
    }

    func update(itinerary: ActiveItinerary?) async {
        self.itinerary = itinerary
        await resync()
    }

    /// The settings changed (a toggle, or the system permissions): choose the regions again.
    func refresh() async {
        await resync()
    }

    /// The user signed out: stop watching and forget the saved places, so nothing fires for a closed session.
    func stop() async {
        places = []
        user = nil
        itinerary = nil
        store.saveMonitoredPlaces([])
        await monitor.stopMonitoring()
    }

    // MARK: Regions

    private func resync() async {
        guard monitor.isAuthorized, await notifier.canPost() else {
            await clearMonitoring()
            return
        }

        let settings = store.loadSettings()
        var selected = ProximityRegionSelector.select(
            places: places,
            user: user,
            itinerary: settings.itineraryEnabled ? itinerary : nil
        )
        if !settings.nearbyPlacesEnabled {
            selected = selected.filter { $0.itineraryRunID != nil }
        }

        store.saveMonitoredPlaces(selected)
        if selected.isEmpty {
            await monitor.stopMonitoring()
        } else {
            await monitor.monitor(selected, radius: ProximityRegionSelector.radius)
        }
        AppLog.proximity.info("Monitoring \(selected.count) places")
    }

    private func clearMonitoring() async {
        guard !store.loadMonitoredPlaces().isEmpty else {
            await monitor.stopMonitoring()
            return
        }
        store.saveMonitoredPlaces([])
        await monitor.stopMonitoring()
        AppLog.proximity.info("Monitoring off: missing location or notification permission")
    }

    // MARK: Entries

    /// The user came within range of `placeID`. Sends the alert if the policy agrees.
    func handleEntry(placeID: String) async {
        let monitored = store.loadMonitoredPlaces()
        guard let snapshot = monitored.first(where: { $0.placeID == placeID }) else { return }

        let currentTime = now()
        let settings = store.loadSettings()
        var history = store.loadHistory().pruned(
            now: currentTime,
            keepingRun: monitored.lazy.compactMap(\.itineraryRunID).first
        )

        guard let candidate = chooseCandidate(
            for: snapshot,
            settings: settings,
            history: history,
            now: currentTime
        ) else {
            store.saveHistory(history)
            return
        }

        let content = ProximityAlertContent.make(
            for: snapshot,
            kind: candidate.kind.deliveryKind,
            now: currentTime,
            timeZone: policy.timeZone
        )
        do {
            try await notifier.post(content)
        } catch {
            AppLog.proximity.error("Failed to post the proximity alert", error: error)
            store.saveHistory(history)
            return
        }
        history.record(candidate, at: currentTime)
        store.saveHistory(history)
    }

    /// The roteiro stop takes priority. Only when the user turned roteiro alerts off does the same place get
    /// judged as a plain nearby place.
    private func chooseCandidate(
        for snapshot: ProximityPlaceSnapshot,
        settings: ProximityAlertSettings,
        history: ProximityAlertHistory,
        now: Date
    ) -> ProximityAlertCandidate? {
        if let runID = snapshot.itineraryRunID {
            let stop = candidate(for: snapshot, kind: .itineraryStop(runID: runID))
            switch policy.decide(stop, settings: settings, history: history, now: now) {
            case .send: return stop
            case .skip(.disabled): break
            case .skip: return nil
            }
        }
        let nearby = candidate(for: snapshot, kind: .nearbyPlace)
        return policy.decide(nearby, settings: settings, history: history, now: now) == .send ? nearby : nil
    }

    private func candidate(
        for snapshot: ProximityPlaceSnapshot,
        kind: ProximityAlertCandidate.Kind
    ) -> ProximityAlertCandidate {
        ProximityAlertCandidate(
            placeID: snapshot.placeID,
            kind: kind,
            openingHours: snapshot.openingHours,
            hasCheckedIn: snapshot.hasCheckedIn
        )
    }
}

private extension ProximityAlertCandidate.Kind {
    var deliveryKind: ProximityAlertDeliveryKind {
        switch self {
        case .nearbyPlace: .nearbyPlace
        case .itineraryStop: .itineraryStop
        }
    }
}
