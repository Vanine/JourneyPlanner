//
//  SharedRouteStore.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 25.04.2026.
//

import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

// Protocol-oriented bridge between persistence and the App Group container.
// The iOS app calls `publish(...)` whenever favorites change; the widget
// timeline provider and the watch app call `loadRoutes()` / `loadDepartures()`
// to render their UI.
protocol SharedRouteStore: Sendable {
    func loadRoutes() -> [SharedRoute]
    func loadDepartures(for routeID: String) -> [SharedDeparture]
    func loadAllDepartures() -> [String: [SharedDeparture]]
    func publishRoutes(_ routes: [SharedRoute])
    func publishDepartures(_ departures: [SharedDeparture], for routeID: String)
}

final class AppGroupRouteStore: SharedRouteStore {
    private let defaults: UserDefaults?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults? = AppGroup.sharedDefaults) {
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadRoutes() -> [SharedRoute] {
        guard let data = defaults?.data(forKey: AppGroup.Keys.savedRoutes) else { return [] }
        return (try? decoder.decode([SharedRoute].self, from: data)) ?? []
    }

    func loadDepartures(for routeID: String) -> [SharedDeparture] {
        let all = loadAllDepartures()
        return all[routeID] ?? []
    }

    func publishRoutes(_ routes: [SharedRoute]) {
        guard let data = try? encoder.encode(routes) else { return }
        defaults?.set(data, forKey: AppGroup.Keys.savedRoutes)
        defaults?.set(Date(), forKey: AppGroup.Keys.lastUpdated)
        reloadWidgets()
        pushToWatch(routes: routes, departures: loadAllDepartures())
    }

    func publishDepartures(_ departures: [SharedDeparture], for routeID: String) {
        var all = loadAllDepartures()
        all[routeID] = departures
        guard let data = try? encoder.encode(all) else { return }
        defaults?.set(data, forKey: AppGroup.Keys.cachedDepartures)
        defaults?.set(Date(), forKey: AppGroup.Keys.lastUpdated)
        reloadWidgets()
        pushToWatch(routes: loadRoutes(), departures: all)
    }

    private func pushToWatch(routes: [SharedRoute], departures: [String: [SharedDeparture]]) {
        #if !os(watchOS)
        WatchSessionRelay.shared.push(routes: routes, departuresByRoute: departures)
        #endif
    }

    func loadAllDepartures() -> [String: [SharedDeparture]] {
        guard let data = defaults?.data(forKey: AppGroup.Keys.cachedDepartures) else { return [:] }
        return (try? decoder.decode([String: [SharedDeparture]].self, from: data)) ?? [:]
    }

    private func reloadWidgets() {
        #if canImport(WidgetKit) && !os(watchOS)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
