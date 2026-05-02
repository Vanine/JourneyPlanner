//
//  SharedRouteSynchronizer.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 26.04.2026.
//

import Foundation

// Bridges domain-level Favorites/Journey models into the lightweight DTOs that
// live in the App Group container. This is intentionally a pure transformation
// layer so the iOS app's domain layer never imports WidgetKit.
@MainActor
final class SharedRouteSynchronizer {
    private let favorites: FavoritesRepository
    private let journeyService: JourneyService
    private let store: SharedRouteStore

    init(favorites: FavoritesRepository, journeyService: JourneyService, store: SharedRouteStore) {
        self.favorites = favorites
        self.journeyService = journeyService
        self.store = store
    }

    // Push the current favorites list into the App Group so the widget and
    // watch app can render the correct list on next refresh.
    func syncRoutes() {
        let routes = favorites.all().map { fav in
            SharedRoute(
                id: "\(fav.origin.id)|\(fav.destination.id)",
                originID: fav.origin.id,
                originName: fav.origin.name,
                destinationID: fav.destination.id,
                destinationName: fav.destination.name,
                savedAt: fav.savedAt
            )
        }
        // Deduplicate routes (multiple journeys may share the same O-D pair).
        var unique: [String: SharedRoute] = [:]
        for route in routes where unique[route.id] == nil { unique[route.id] = route }
        store.publishRoutes(Array(unique.values).sorted { $0.savedAt > $1.savedAt })
    }

    // Refresh the cached upcoming departures for every saved route. Called
    // from the iOS app on launch / on resume so the widget always has fresh
    // data even before its own timeline fires.
    func refreshDepartures() async {
        let routes = store.loadRoutes()
        for route in routes {
            let origin = Location(id: route.originID, name: route.originName, subtitle: "")
            let destination = Location(id: route.destinationID, name: route.destinationName, subtitle: "")
            do {
                let journeys = try await journeyService.journeys(from: origin, to: destination)
                let departures: [SharedDeparture] = journeys.prefix(4).compactMap { journey in
                    guard let firstTransit = journey.legs.first(where: { $0.transport != .walk }) else { return nil }
                    return SharedDeparture(
                        id: "\(route.id)-\(journey.id)",
                        routeID: route.id,
                        line: firstTransit.line,
                        transport: firstTransit.transport.rawValue,
                        platform: firstTransit.platform,
                        destination: route.destinationName,
                        departure: firstTransit.departure,
                        delayMinutes: firstTransit.delayMinutes
                    )
                }
                store.publishDepartures(departures, for: route.id)
            } catch {
                continue
            }
        }
    }
}
