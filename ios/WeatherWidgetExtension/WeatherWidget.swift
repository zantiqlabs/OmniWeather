import WidgetKit
import SwiftUI

// MARK: - Shared keys (must match Dart's _WidgetKeys)

private enum WidgetKeys {
    static let appGroup       = "group.com.zantiqlabs.omniweather"
    static let locationName   = "widget_location_name"
    static let temperature    = "widget_temperature"
    static let conditionText  = "widget_condition"
    static let lastUpdated    = "widget_last_updated"
}

// MARK: - Entry model

struct WeatherEntry: TimelineEntry {
    let date: Date
    let locationName: String
    let temperature: String
    let condition: String
    let lastUpdated: String
}

// MARK: - Provider

struct WeatherProvider: TimelineProvider {

    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(date: .now, locationName: "London",
                     temperature: "14°C", condition: "Partly cloudy",
                     lastUpdated: "")
    }

    func getSnapshot(in context: Context,
                     completion: @escaping (WeatherEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        let entry = readEntry()
        // Refresh at most once every 15 minutes; the app will push sooner on resume.
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    // MARK: Read from shared UserDefaults (written by home_widget Dart package)

    private func readEntry() -> WeatherEntry {
        let defaults = UserDefaults(suiteName: WidgetKeys.appGroup)
        let location  = defaults?.string(forKey: WidgetKeys.locationName) ?? "—"
        let temp      = defaults?.string(forKey: WidgetKeys.temperature)  ?? "—"
        let condition = defaults?.string(forKey: WidgetKeys.conditionText) ?? "—"
        let updated   = formatUpdated(defaults?.string(forKey: WidgetKeys.lastUpdated))
        return WeatherEntry(date: .now, locationName: location,
                            temperature: temp, condition: condition,
                            lastUpdated: updated)
    }

    private func formatUpdated(_ iso: String?) -> String {
        guard let iso = iso, !iso.isEmpty else { return "" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        // Fall back to without fractional seconds
        let date = formatter.date(from: iso) ?? {
            let f2 = ISO8601DateFormatter()
            return f2.date(from: iso)
        }()
        guard let date = date else { return "" }
        let df = DateFormatter()
        df.timeStyle = .short
        df.dateStyle = .none
        return "Updated \(df.string(from: date))"
    }
}

// MARK: - Widget view

struct WeatherWidgetEntryView: View {
    var entry: WeatherEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.05, green: 0.11, blue: 0.16).opacity(0.95))

            VStack(alignment: .leading, spacing: 2) {
                // Location
                Text(entry.locationName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(white: 0.65))
                    .lineLimit(1)

                // Temperature + condition
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(entry.temperature)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(entry.condition)
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.65))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Last updated
                if !entry.lastUpdated.isEmpty {
                    Text(entry.lastUpdated)
                        .font(.system(size: 9))
                        .foregroundColor(Color(white: 0.40))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Widget declaration

@main
struct WeatherWidget: Widget {
    let kind: String = "WeatherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherProvider()) { entry in
            WeatherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("OmniWeather")
        .description("Current temperature and conditions at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

struct WeatherWidget_Previews: PreviewProvider {
    static var previews: some View {
        WeatherWidgetEntryView(
            entry: WeatherEntry(date: .now, locationName: "London",
                                temperature: "14°C", condition: "Partly cloudy",
                                lastUpdated: "Updated 3:45 PM")
        )
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
