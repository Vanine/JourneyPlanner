//
//  Location.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 18.03.2026.
//

import Foundation

nonisolated struct Location: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let name: String
    let subtitle: String
}
