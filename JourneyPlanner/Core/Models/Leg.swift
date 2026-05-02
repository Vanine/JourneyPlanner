//
//  Leg.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 18.03.2026.
//

import Foundation

enum TransportType: String, Codable, Sendable {
    case train, bus, tram, metro, walk

    var symbolName: String {
        switch self {
        case .train: return "tram.fill"
        case .bus: return "bus.fill"
        case .tram: return "tram"
        case .metro: return "tram.tunnel.fill"
        case .walk: return "figure.walk"
        }
    }

    var displayName: String {
        switch self {
        case .train: return "Train"
        case .bus: return "Bus"
        case .tram: return "Tram"
        case .metro: return "Metro"
        case .walk: return "Walk"
        }
    }
}

nonisolated struct Leg: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let transport: TransportType
    let line: String
    let platform: String?
    let from: String
    let to: String
    let departure: Date
    let arrival: Date
    let delayMinutes: Int

    var isDelayed: Bool { delayMinutes > 0 }
}
