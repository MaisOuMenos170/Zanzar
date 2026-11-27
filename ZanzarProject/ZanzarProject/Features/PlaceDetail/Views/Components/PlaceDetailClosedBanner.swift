import SwiftUI

/// Shown while the place is closed: when it opens, and a reminder for that moment. The check-in stays available
/// (the hours come from a source that can be wrong, so they never lock anyone out).
struct PlaceDetailClosedBanner: View {
    let opensAt: Date?
    let hasReminder: Bool
    let onToggleReminder: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "clock")
                .scaledFont(size: 18, weight: .semibold)
                .foregroundStyle(Color.brandNeutral950)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("placeDetail.closedBanner.title")
                    .scaledFont(size: 14, weight: .semibold)
                    .foregroundStyle(Color.brandNeutral950)
                if let opensAt {
                    Text(verbatim: Self.opensMessage(opensAt: opensAt, now: Date()))
                        .scaledFont(size: 13)
                        .foregroundStyle(Color.brandNeutral700)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if opensAt != nil {
                Button(action: onToggleReminder) {
                    Text(hasReminder ? "placeDetail.closedBanner.reminderOn" : "placeDetail.closedBanner.reminderOff")
                        .scaledFont(size: 13, weight: .semibold)
                        .multilineTextAlignment(.trailing)
                        .frame(minHeight: 44)
                }
                .tint(Color.brandBlue600)
                .accessibilityHint(Text("placeDetail.closedBanner.reminderHint"))
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .padding(.vertical, 4)
        .background(Color.brandNeutral50, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16).strokeBorder(Color.brandNeutral200, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }

    /// "Abre hoje às 9h.", "Abre amanhã às 9h." or "Abre sexta-feira às 10h."
    static func opensMessage(
        opensAt: Date,
        now: Date,
        in timeZone: TimeZone = OpeningHours.defaultTimeZone
    ) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let time = PlaceDetail.closingTime(opensAt, in: timeZone)
        if calendar.isDate(opensAt, inSameDayAs: now) {
            return L10n.string("placeDetail.closedBanner.opensToday", time)
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(opensAt, inSameDayAs: tomorrow) {
            return L10n.string("placeDetail.closedBanner.opensTomorrow", time)
        }
        var weekdayFormat = Date.FormatStyle(timeZone: timeZone).weekday(.wide)
        weekdayFormat.locale = AppLanguageSettings.current.locale
        return L10n.string("placeDetail.closedBanner.opensOn", opensAt.formatted(weekdayFormat), time)
    }
}

#Preview {
    VStack {
        PlaceDetailClosedBanner(opensAt: .now.addingTimeInterval(3600 * 5), hasReminder: false) {}
        PlaceDetailClosedBanner(opensAt: .now.addingTimeInterval(3600 * 30), hasReminder: true) {}
        PlaceDetailClosedBanner(opensAt: nil, hasReminder: false) {}
    }
    .padding()
}
