//
//  PersistenceController.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 02.04.2026.
//

import Foundation
import SwiftData

// Owns the shared SwiftData ModelContainer for the app. Centralising it here
// keeps the schema in one place and lets repositories receive a ready-made
// ModelContext without each knowing how to build the stack.
@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer

    var context: ModelContext { container.mainContext }

    private init() {
        let schema = Schema([
            FavoriteJourneyEntity.self,
            RecentSearchEntity.self
        ])
        do {
            self.container = try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("Failed to initialise SwiftData container: \(error)")
        }
    }
}
