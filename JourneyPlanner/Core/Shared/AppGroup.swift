//
//  AppGroup.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 24.04.2026.
//

import Foundation

enum AppGroup {
    static let identifier = "group.app.journey.planner"

    enum Keys {
        static let savedRoutes = "shared.savedRoutes.v1"
        static let cachedDepartures = "shared.cachedDepartures.v1"
        static let lastUpdated = "shared.lastUpdated.v1"
    }

    static var sharedDefaults: UserDefaults? {
        if let suite = UserDefaults(suiteName: identifier),
           suite != UserDefaults.standard {
            return suite
        }
        return UserDefaults.standard
    }
}
