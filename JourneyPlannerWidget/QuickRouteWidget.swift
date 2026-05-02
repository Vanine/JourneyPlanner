//
//  QuickRouteWidget.swift
//  JourneyPlannerWidget
//
//  Created by Vanine Ghazaryan on 28.04.2026.
//

import SwiftUI
import WidgetKit

struct QuickRouteEntry: TimelineEntry {
    let date: Date
    let routes: [SharedRoute]
}

struct QuickRouteProvider: TimelineProvider {
    let reader = WidgetSharedReader()

    func placeholder(in context: Context) -> QuickRouteEntry {
        QuickRouteEntry(date: Date(), routes: Self.sampleRoutes)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickRouteEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickRouteEntry>) -> Void) {
        completion(Timeline(entries: [currentEntry()], policy: .after(Date().addingTimeInterval(60 * 15))))
    }

    private func currentEntry() -> QuickRouteEntry {
        QuickRouteEntry(date: Date(), routes: reader.routes())
    }

    private static let sampleRoutes: [SharedRoute] = [
        SharedRoute(id: "1", originID: "ber-hbf", originName: "Berlin Hbf", destinationID: "ber-alex", destinationName: "Alexanderplatz", savedAt: Date()),
        SharedRoute(id: "2", originID: "ber-alex", originName: "Alexanderplatz", destinationID: "ber-fhain", destinationName: "Frankfurter Allee", savedAt: Date()),
        SharedRoute(id: "3", originID: "ham-hbf", originName: "Hamburg Hbf", destinationID: "ham-altona", destinationName: "Altona", savedAt: Date())
    ]
}

struct QuickRouteWidget: Widget {
    let kind: String = "QuickRouteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickRouteProvider()) { entry in
            QuickRouteEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color(red: 0.06, green: 0.08, blue: 0.16),
                                 Color(red: 0.12, green: 0.10, blue: 0.22)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .configurationDisplayName("Quick Routes")
        .description("Tap any saved route to jump straight to results.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct QuickRouteEntryView: View {
    let entry: QuickRouteEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if entry.routes.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "bookmark")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.5))
                Text("Save routes in the app")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "bookmark.fill")
                        .imageScale(.small)
                        .foregroundStyle(.blue)
                    Text("Saved Routes")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                }

                let visible = Array(entry.routes.prefix(family == .systemMedium ? 3 : 2))
                ForEach(visible.prefix(2)) { route in
                    RouteRow(route: route)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

private struct RouteRow: View {
    let route: SharedRoute
    var body: some View {
        Link(destination: DeepLink.url(for: route) ?? URL(string: "journeyplanner://")!) {
            HStack(spacing: 8) {
                Circle()
                    .fill(.blue.opacity(0.6))
                    .frame(width: 6, height: 6)
                VStack(alignment: .leading, spacing: 1) {
                    Text(route.originName)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                    Text(route.destinationName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .imageScale(.small)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}
