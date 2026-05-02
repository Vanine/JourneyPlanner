//
//  RecentSearchesRepository.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 03.04.2026.
//

import Foundation
import SwiftData

struct RecentSearch: Codable, Hashable, Sendable, Identifiable {
    let origin: Location
    let destination: Location
    let savedAt: Date

    var id: String { "\(origin.id)→\(destination.id)" }
}

@MainActor
protocol RecentSearchesRepository: AnyObject {
    func all() -> [RecentSearch]
    func add(origin: Location, destination: Location)
    func clear()
}

// SwiftData-backed store. Keeps the last N searches, deduplicated by
// origin/destination pair, most recent first.
@MainActor
final class SwiftDataRecentSearchesRepository: RecentSearchesRepository {
    private let limit = 5
    private let context: ModelContext
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(context: ModelContext) {
        self.context = context
    }

    func all() -> [RecentSearch] {
        let descriptor = FetchDescriptor<RecentSearchEntity>(
            sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
        )
        let entities = (try? context.fetch(descriptor)) ?? []
        return entities.compactMap { try? decoder.decode(RecentSearch.self, from: $0.payload) }
    }

    func add(origin: Location, destination: Location) {
        let recent = RecentSearch(origin: origin, destination: destination, savedAt: Date())
        let id = recent.id

        if let existing = entity(for: id) {
            context.delete(existing)
        }

        guard let data = try? encoder.encode(recent) else { return }
        context.insert(RecentSearchEntity(id: id, savedAt: recent.savedAt, payload: data))

        let descriptor = FetchDescriptor<RecentSearchEntity>(
            sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
        )
        if let entities = try? context.fetch(descriptor), entities.count > limit {
            for stale in entities.dropFirst(limit) {
                context.delete(stale)
            }
        }
        try? context.save()
    }

    func clear() {
        let descriptor = FetchDescriptor<RecentSearchEntity>()
        if let entities = try? context.fetch(descriptor) {
            for entity in entities { context.delete(entity) }
            try? context.save()
        }
    }

    private func entity(for id: String) -> RecentSearchEntity? {
        var descriptor = FetchDescriptor<RecentSearchEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}
