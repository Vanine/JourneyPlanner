//
//  WatchDataStore.swift
//  JourneyPlannerWatch
//
//  Created by Vanine Ghazaryan on 28.04.2026.
//

import Foundation

// Protocol-oriented service the watch ViewModels depend on. The default
// implementation reads from the local UserDefaults populated by the
// WatchConnectivity relay. Tests / previews can swap in an in-memory impl.
protocol WatchDataStore: Sendable {
    func loadRoutes() async -> [SharedRoute]
    func loadDepartures(for routeID: String) async -> [SharedDeparture]
}

final class LocalWatchDataStore: WatchDataStore {
    private let defaults: UserDefaults
    private let decoder: JSONDecoder

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func loadRoutes() async -> [SharedRoute] {
        // Tiny artificial latency so the watch UI exercises its loading state.
        try? await Task.sleep(for: .milliseconds(120))
        guard let data = defaults.data(forKey: WatchLocalStore.Keys.routes) else { return [] }
        let routes = (try? decoder.decode([SharedRoute].self, from: data)) ?? []
        return routes.sorted { $0.savedAt > $1.savedAt }
    }

    func loadDepartures(for routeID: String) async -> [SharedDeparture] {
        try? await Task.sleep(for: .milliseconds(150))
        guard let data = defaults.data(forKey: WatchLocalStore.Keys.departures) else { return [] }
        let all = (try? decoder.decode([String: [SharedDeparture]].self, from: data)) ?? [:]
        return (all[routeID] ?? [])
            .filter { $0.departure > Date().addingTimeInterval(-60) }
            .sorted { $0.departure < $1.departure }
    }
}
