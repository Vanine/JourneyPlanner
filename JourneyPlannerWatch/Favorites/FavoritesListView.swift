//
//  FavoritesListView.swift
//  JourneyPlannerWatch
//
//  Created by Vanine Ghazaryan on 29.04.2026.
//

import SwiftUI
import Combine

struct FavoritesListView: View {
    @Environment(\.watchContainer) private var container
    @State private var viewModel: FavoritesViewModel?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Routes")
                .toolbar {
                    if viewModel?.state != .empty {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                Task { await viewModel?.refresh() }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                    }
                }
        }
        .task {
            if viewModel == nil {
                viewModel = FavoritesViewModel(store: container.store)
            }
            await viewModel?.load()
            // Proactively pull the freshest snapshot from the iPhone on
            // every appear — cheap, idempotent, and keeps the list honest.
            WatchSessionRelay.shared.requestSnapshot()
        }
        .onReceive(NotificationCenter.default.publisher(for: .watchSyncDidUpdate)) { _ in
            // The phone just delivered a fresh favorites snapshot — reload.
            Task { await viewModel?.refresh() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel?.state ?? .idle {
        case .idle, .loading:
            ProgressView()
                .controlSize(.regular)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty:
            VStack(spacing: 10) {
                EmptyStateView(
                    title: "No saved routes"
                )
                Button {
                    WatchSessionRelay.shared.requestSnapshot()
                    Task { await viewModel?.refresh() }
                } label: {
                    Label("Sync from iPhone", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            EmptyStateView(symbol: "exclamationmark.triangle", title: "Couldn’t load", message: message)
        case .loaded(let routes):
            List {
                ForEach(routes) { route in
                    NavigationLink(value: route) {
                        RouteRow(route: route)
                    }
                }
            }
            .listStyle(.carousel)
            .navigationDestination(for: SharedRoute.self) { route in
                DeparturesView(route: route)
            }
            .refreshable { await viewModel?.refresh() }
        }
    }
}

private struct RouteRow: View {
    let route: SharedRoute

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(route.originName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            HStack(spacing: 4) {
                Image(systemName: "arrow.down")
                    .imageScale(.small)
                    .foregroundStyle(.blue)
                Text(route.destinationName)
                    .font(.headline)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

struct EmptyStateView: View {
    let symbol: String?
    let title: String
    let message: String?

    init(symbol: String? = nil, title: String, message: String? = nil) {
        self.symbol = symbol
        self.title = title
        self.message = message
    }

    var body: some View {
        VStack(spacing: 8) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            if let message {
                Text(message)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}
