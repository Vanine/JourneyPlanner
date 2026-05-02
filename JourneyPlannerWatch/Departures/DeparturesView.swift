//
//  DeparturesView.swift
//  JourneyPlannerWatch
//
//  Created by Vanine Ghazaryan on 29.04.2026.
//

import SwiftUI

struct DeparturesView: View {
    @Environment(\.watchContainer) private var container
    let route: SharedRoute
    @State private var viewModel: DeparturesViewModel?

    var body: some View {
        content
            .navigationTitle(route.destinationName)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel?.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                if viewModel == nil {
                    viewModel = DeparturesViewModel(route: route, store: container.store)
                }
                await viewModel?.load()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel?.state ?? .idle {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty:
            EmptyStateView(
                symbol: "tram",
                title: "No departures",
                message: "Pull to refresh once you’re online."
            )
        case .failed(let message):
            EmptyStateView(symbol: "exclamationmark.triangle", title: "Error", message: message)
        case .loaded(let departures):
            List(departures) { departure in
                DepartureRow(departure: departure)
            }
            .listStyle(.carousel)
            .refreshable { await viewModel?.refresh() }
        }
    }
}

private struct DepartureRow: View {
    let departure: SharedDeparture

    private var minutesAway: Int {
        max(0, Int(departure.departure.timeIntervalSinceNow / 60))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: departure.transportSymbol)
                    .foregroundStyle(.blue)
                Text(departure.line)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(departure.statusText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(departure.isDelayed ? .orange : .green)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(timeText)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                Spacer()
                Text(minutesAway == 0 ? "Now" : "\(minutesAway) min")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let platform = departure.platform {
                Text("Platform \(platform)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: departure.departure)
    }
}
