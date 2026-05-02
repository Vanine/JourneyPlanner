//
//  PersistenceModels.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 02.04.2026.
//

import Foundation
import SwiftData

// SwiftData entities that persist value-type domain models as encoded JSON
// payloads. We keep indexed scalar fields (id, savedAt) for fast queries and
// stable ordering, while the rich nested `Journey`/`Location` graphs live in
// the payload — this avoids fragile relationship migrations as the domain
// model evolves.
@Model
final class FavoriteJourneyEntity {
    @Attribute(.unique) var id: String
    var savedAt: Date
    var payload: Data

    init(id: String, savedAt: Date, payload: Data) {
        self.id = id
        self.savedAt = savedAt
        self.payload = payload
    }
}

@Model
final class RecentSearchEntity {
    @Attribute(.unique) var id: String
    var savedAt: Date
    var payload: Data

    init(id: String, savedAt: Date, payload: Data) {
        self.id = id
        self.savedAt = savedAt
        self.payload = payload
    }
}
