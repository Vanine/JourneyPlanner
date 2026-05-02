//
//  SharedRoute.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 24.04.2026.
//

import Foundation

// Lightweight DTOs that travel through the App Group shared container. We
// intentionally keep these flat and free of UIKit/SwiftUI dependencies so they
// can be decoded inside the widget extension and the watchOS app.
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
}
