//
//  NextDepartureWidget.swift
//  JourneyPlannerWidget
//
//  Created by Vanine Ghazaryan on 27.04.2026.
//

import SwiftUI
import WidgetKit

// MARK: - Timeline entry

struct NextDepartureEntry: TimelineEntry {
    let date: Date
    let route: SharedRoute?
    let departure: SharedDeparture?
}

// MARK: - Timeline provider
struct NextDepartureProvider: TimelineProvider {
    let reader = WidgetSharedReader()

    func placeholder(in context: Context) -> NextDepartureEntry {
        NextDepartureEntry(date: Date(), route: Self.sampleRoute, departure: Self.sampleDeparture)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextDepartureEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextDepartureEntry>) -> Void) {
        let entry = currentEntry()
        let nextRefresh = Date().addingTimeInterval(60 * 5)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func currentEntry() -> NextDepartureEntry {
        let routes = reader.routes()
        guard let route = routes.first else {
            return NextDepartureEntry(date: Date(), route: nil, departure: nil)
        }
        let upcoming = reader.departures(for: route.id)
            .filter { $0.departure > Date().addingTimeInterval(-30) }
            .sorted { $0.departure < $1.departure }
        return NextDepartureEntry(date: Date(), route: route, departure: upcoming.first)
    }

    private static let sampleRoute = SharedRoute(
        id: "ber-hbf|ber-alex",
        originID: "ber-hbf",
        originName: "Berlin Hbf",
        destinationID: "ber-alex",
        destinationName: "Alexanderplatz",
        savedAt: Date()
    )

    private static let sampleDeparture = SharedDeparture(
        id: "sample",
        routeID: "ber-hbf|ber-alex",
        line: "ICE 1602",
        transport: "train",
        platform: "5",
        destination: "Alexanderplatz",
        departure: Date().addingTimeInterval(60 * 8),
        delayMinutes: 0
    )
}

// MARK: - Widget definition

struct NextDepartureWidget: Widget {
    let kind: String = "NextDepartureWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextDepartureProvider()) { entry in
            NextDepartureEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color(red: 0.07, green: 0.10, blue: 0.18),
                                 Color(red: 0.10, green: 0.14, blue: 0.26)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Next Departure")
        .description("See the next train, bus or tram for your top saved route.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Entry view

struct NextDepartureEntryView: View {
    let entry: NextDepartureEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch (entry.route, entry.departure) {
        case (.none, _):
            EmptyStateView()
        case (.some(let route), .none):
            NoDeparturesView(route: route)
        case (.some(let route), .some(let departure)):
            DepartureView(route: route, departure: departure, family: family)
        }
    }
}

private struct DepartureView: View {
    let route: SharedRoute
    let departure: SharedDeparture
    let family: WidgetFamily

    private var minutesAway: Int {
        max(0, Int(departure.departure.timeIntervalSinceNow / 60))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: departure.transportSymbol)
                    .foregroundStyle(.blue)
                Text(departure.line)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer(minLength: 0)
                StatusPill(isDelayed: departure.isDelayed)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(timeText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(minutesAway == 0 ? "Departing now" : "in \(minutesAway) min")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(route.originName)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                    Image(systemName: "arrow.down.right")
                        .imageScale(.small)
                        .foregroundStyle(.white.opacity(0.4))
                    Text(route.destinationName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                if let platform = departure.platform {
                    PlatformBadge(platform: platform)
                }
            }
        }
        .padding(.vertical, 20)
        .widgetURL(DeepLink.url(for: route))
    }

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: departure.departure)
    }
}

private struct StatusPill: View {
    let isDelayed: Bool
    var body: some View {
        Text(isDelayed ? "Delayed" : "On time")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(isDelayed ? .orange : .green)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                (isDelayed ? Color.orange : Color.green).opacity(0.18),
                in: Capsule()
            )
    }
}

private struct PlatformBadge: View {
    let platform: String
    var body: some View {
        VStack(spacing: 0) {
            Text("PLT")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))
            Text(platform)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "star")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.5))
            Text("No saved routes")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
            Text("Add a favorite in the app")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct NoDeparturesView: View {
    let route: SharedRoute
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(route.originName)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
            Text(route.destinationName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Spacer(minLength: 4)
            HStack(spacing: 4) {
                Image(systemName: "wifi.exclamationmark")
                Text("No departures")
            }
            .font(.caption)
            .foregroundStyle(.orange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(DeepLink.url(for: route))
    }
}
