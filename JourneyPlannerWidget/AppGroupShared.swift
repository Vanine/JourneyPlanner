//
//  AppGroupShared.swift
//  JourneyPlannerWidget
//
//  Created by Vanine Ghazaryan on 24.04.2026.
//

import Foundation
import WidgetKit

enum AppGroup {
    static let identifier = "group.app.journey.planner"

    enum Keys {
        static let savedRoutes = "shared.savedRoutes.v1"
        static let cachedDepartures = "shared.cachedDepartures.v1"
        static let lastUpdated = "shared.lastUpdated.v1"
    }

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }
}

struct SharedRoute: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let originID: String
    let originName: String
    let destinationID: String
    let destinationName: String
    let savedAt: Date
}

struct SharedDeparture: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let routeID: String
    let line: String
    let transport: String
    let platform: String?
    let destination: String
    let departure: Date
    let delayMinutes: Int

    var isDelayed: Bool { delayMinutes > 0 }
    var statusText: String { isDelayed ? "Delayed \(delayMinutes)m" : "On time" }

    var transportSymbol: String {
        switch transport {
        case "train": return "tram.fill"
        case "bus": return "bus.fill"
        case "tram": return "tram"
        case "metro": return "tram.tunnel.fill"
        default: return "figure.walk"
        }
    }
}

struct WidgetSharedReader {
    let defaults: UserDefaults?
    private let decoder: JSONDecoder

    init(defaults: UserDefaults? = AppGroup.sharedDefaults) {
        self.defaults = defaults
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func routes() -> [SharedRoute] {
        guard let data = defaults?.data(forKey: AppGroup.Keys.savedRoutes) else { return [] }
        return (try? decoder.decode([SharedRoute].self, from: data)) ?? []
    }

    func departures(for routeID: String) -> [SharedDeparture] {
        guard let data = defaults?.data(forKey: AppGroup.Keys.cachedDepartures) else { return [] }
        let all = (try? decoder.decode([String: [SharedDeparture]].self, from: data)) ?? [:]
        return all[routeID] ?? []
    }
}

enum DeepLink {
    static func url(for route: SharedRoute) -> URL? {
        var components = URLComponents()
        components.scheme = "journeyplanner"
        components.host = "route"
        components.queryItems = [
            URLQueryItem(name: "originId", value: route.originID),
            URLQueryItem(name: "originName", value: route.originName),
            URLQueryItem(name: "destId", value: route.destinationID),
            URLQueryItem(name: "destName", value: route.destinationName)
        ]
        return components.url
    }
}
