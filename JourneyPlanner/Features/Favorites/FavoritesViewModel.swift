//
//  FavoritesViewModel.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 06.04.2026.
//

import Foundation

@MainActor
final class FavoritesViewModel {

    private let favorites: FavoritesRepository
    private(set) var items: [FavoriteJourney] = []

    var onChange: (() -> Void)?

    init(favorites: FavoritesRepository) {
        self.favorites = favorites
    }

    func reload() {
        items = favorites.all()
        onChange?()
    }

    func remove(at index: Int) {
        guard items.indices.contains(index) else { return }
        let item = items[index]
        favorites.remove(id: item.id)
        items.remove(at: index)
        onChange?()
    }

    func remove(_ item: FavoriteJourney) {
        favorites.remove(id: item.id)
        if let i = items.firstIndex(of: item) { items.remove(at: i) }
        onChange?()
    }
}
