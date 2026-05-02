//
//  Models.swift
//  JourneyPlannerWatch
//
//  Created by Vanine Ghazaryan on 24.04.2026.
//

import Foundation

// Shared DTO contract mirrored from the iOS app target.
//
// NOTE: App Groups do NOT bridge the iPhone <-> Apple Watch boundary — they
// only share data between processes on the same device (iOS app + widget
// extension). The watch is a separate device, so favorites travel over
// WatchConnectivity (see `WatchSessionRelay`) and are persisted into the
// watch's own `UserDefaults.standard` under `WatchLocalStore.Keys`.
//
// This file therefore only redeclares the Codable DTO types so both targets
// can decode the same JSON payload — it does NOT define an App Group suite.

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
