//
//  Journey.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 18.03.2026.
//

import Foundation

nonisolated struct Journey: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let departure: Date
    let arrival: Date
    let legs: [Leg]

    var duration: TimeInterval { arrival.timeIntervalSince(departure) }
    var transferCount: Int { max(0, legs.filter { $0.transport != .walk }.count - 1) }
}
