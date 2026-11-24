//
//  ZanzarWidget.swift
//  ZanzarWidget
//

import WidgetKit
import SwiftUI

/// Timeline provider for the Lero widget: shows the next itinerary stop or a
/// Timeline provider for the Zanzar widget: shows the next itinerary stop or a
/// nudge to check in nearby, refreshed from the app's shared data.
struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), nextStop: nil)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: .now, configuration: configuration, nextStop: await nextStop())
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = SimpleEntry(date: .now, configuration: configuration, nextStop: await nextStop())
        // Refresh every hour so the next stop stays current.
        return Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(60 * 60)))
    }

    /// Reads the next itinerary stop from the app's shared store. Falls back to nil
    /// when the user has no active itinerary, in which case the widget shows a check-in nudge.
    private func nextStop() async -> String? {
        guard let data = UserDefaults(suiteName: "group.zanzarGroup")?.data(forKey: "zanzar.widgetNextStop"),
              let stop = try? JSONDecoder().decode(WidgetNextStop.self, from: data) else {
            return nil
        }
        return stop.name
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    /// Name of the next itinerary stop, or nil when there is no active itinerary.
    let nextStop: String?
}

/// Payload written by the app so the widget can display the next stop.
struct WidgetNextStop: Codable {
    let name: String
}

struct ZanzarWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color.blue.opacity(0.1).gradient)

            VStack(spacing: 12) {
                if let nextStop = entry.nextStop {
                    Text("nextStop.title")
                        .font(.headline)
                        .foregroundStyle(.blue)
                    Text(nextStop)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                } else {
                    Text("widget.checkInNudge.title")
                        .font(.headline)
                        .foregroundStyle(.blue)
                    Text("widget.checkInNudge.message")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct ZanzarWidget: Widget {
    let kind: String = "ZanzarWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            ZanzarWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("widget.displayName")
        .description("widget.description")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        ConfigurationAppIntent()
    }

    fileprivate static var starEyes: ConfigurationAppIntent {
        ConfigurationAppIntent()
    }
}

#Preview(as: .systemSmall) {
    ZanzarWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley, nextStop: "Bar do Zé")
    SimpleEntry(date: .now, configuration: .starEyes, nextStop: nil)
}
