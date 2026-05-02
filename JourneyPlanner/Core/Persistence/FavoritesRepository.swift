//
//  FavoritesRepository.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 03.04.2026.
//

import Foundation
import SwiftData

nonisolated struct FavoriteJourney: Codable, Hashable, Sendable, Identifiable {
    let journey: Journey
    let origin: Location
    let destination: Location
    let savedAt: Date

    var id: String { Self.makeID(origin: origin, destination: destination, journey: journey) }

    static func makeID(origin: Location, destination: Location, journey: Journey) -> String {
        "\(origin.id)|\(destination.id)|\(journey.id)"
    }
}

@MainActor
protocol FavoritesRepository: AnyObject {
    func all() -> [FavoriteJourney]
    func contains(_ id: String) -> Bool
    @discardableResult
    func toggle(journey: Journey, origin: Location, destination: Location) -> Bool
    func remove(id: String)
}

extension Notification.Name {
    static let favoritesDidChange = Notification.Name("app.journey.planner.favoritesDidChange")
}

@MainActor
final class SwiftDataFavoritesRepository: FavoritesRepository {
    private let context: ModelContext
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(context: ModelContext) {
        self.context = context
    }

    func all() -> [FavoriteJourney] {
        let descriptor = FetchDescriptor<FavoriteJourneyEntity>(
            sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
        )
        let entities = (try? context.fetch(descriptor)) ?? []
        return entities.compactMap { try? decoder.decode(FavoriteJourney.self, from: $0.payload) }
    }

    func contains(_ id: String) -> Bool {
        entity(for: id) != nil
    }

    @discardableResult
    func toggle(journey: Journey, origin: Location, destination: Location) -> Bool {
        let id = FavoriteJourney.makeID(origin: origin, destination: destination, journey: journey)
        if let existing = entity(for: id) {
            context.delete(existing)
            try? context.save()
            notifyChange()
            return false
        }
        let favorite = FavoriteJourney(journey: journey, origin: origin, destination: destination, savedAt: Date())
        guard let data = try? encoder.encode(favorite) else { return false }
        context.insert(FavoriteJourneyEntity(id: id, savedAt: favorite.savedAt, payload: data))
        try? context.save()
        notifyChange()
        return true
    }

    func remove(id: String) {
        guard let existing = entity(for: id) else { return }
        context.delete(existing)
        try? context.save()
        notifyChange()
    }

    private func notifyChange() {
        NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
    }

    private func entity(for id: String) -> FavoriteJourneyEntity? {
        var descriptor = FetchDescriptor<FavoriteJourneyEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}
