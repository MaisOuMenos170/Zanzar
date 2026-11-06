import Foundation

/// What a proximity notification says, and which place it opens.
nonisolated struct ProximityAlertContent: Hashable, Sendable {
    let placeID: String
    let kind: ProximityAlertDeliveryKind
    let title: String
    let body: String
}

extension ProximityAlertContent {
    /// The place name as the title; the body says the user is close, or that this is their next stop, and
    /// until when the place is open when the hours are known.
    static func make(
        for snapshot: ProximityPlaceSnapshot,
        kind: ProximityAlertDeliveryKind,
        now: Date,
        timeZone: TimeZone = OpeningHours.defaultTimeZone
    ) -> ProximityAlertContent {
        let status = snapshot.openingHours?.status(at: now, in: timeZone)
        let body: String
        switch (kind, status) {
        case (.nearbyPlace, .open(let closesAt?)):
            body = L10n.string("proximity.alert.nearby.body.openUntil", closingTime(closesAt, in: timeZone))
        case (.nearbyPlace, .open(nil)):
            body = L10n.string("proximity.alert.nearby.body.open24Hours")
        case (.nearbyPlace, _):
            body = L10n.string("proximity.alert.nearby.body")
        case (.itineraryStop, .open(let closesAt?)):
            body = L10n.string("proximity.alert.stop.body.openUntil", closingTime(closesAt, in: timeZone))
        case (.itineraryStop, _):
            body = L10n.string("proximity.alert.stop.body")
        }
        return ProximityAlertContent(placeID: snapshot.placeID, kind: kind, title: snapshot.name, body: body)
    }

    private static func closingTime(_ date: Date, in timeZone: TimeZone) -> String {
        date.formatted(Date.FormatStyle(date: .omitted, time: .shortened, timeZone: timeZone))
    }
}
