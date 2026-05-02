//
//  SearchViewModel.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 23.03.2026.
//

import Foundation

@MainActor
final class SearchViewModel {

    enum Field { case from, to }

    private let locationService: LocationService
    private let recents: RecentSearchesRepository

    private(set) var origin: Location?
    private(set) var destination: Location?
    private(set) var suggestions: [Location] = []
    private(set) var recentSearches: [RecentSearch] = []
    private(set) var activeField: Field?

    var onSuggestionsChanged: (() -> Void)?
    var onSelectionChanged: (() -> Void)?
    var onRecentsChanged: (() -> Void)?

    private var searchTask: Task<Void, Never>?

    init(locationService: LocationService, recents: RecentSearchesRepository) {
        self.locationService = locationService
        self.recents = recents
        self.recentSearches = recents.all()
    }

    var canSearch: Bool { origin != nil && destination != nil && origin != destination }

    var showsRecents: Bool { suggestions.isEmpty && !recentSearches.isEmpty }

    func setActiveField(_ field: Field?) {
        activeField = field
    }

    func update(field: Field, query: String) {
        activeField = field
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(180))
            guard !Task.isCancelled, let self else { return }
            do {
                let results = try await self.locationService.search(query: query)
                guard !Task.isCancelled else { return }
                self.suggestions = results
                self.onSuggestionsChanged?()
            } catch {
                self.suggestions = []
                self.onSuggestionsChanged?()
            }
        }
    }

    func select(_ location: Location, into field: Field?) {
        // Only fall back to the last explicitly-focused field. We deliberately
        // do NOT auto-pick a side based on which value is currently empty —
        // doing so was the source of "to gets selected automatically when I
        // pick a from value" reports.
        guard let target = field ?? activeField else { return }
        switch target {
        case .from: origin = location
        case .to: destination = location
        }
        suggestions = []
        onSuggestionsChanged?()
        onSelectionChanged?()
    }

    func swap() {
        let tmp = origin
        origin = destination
        destination = tmp
        onSelectionChanged?()
    }

    // A recent search represents a complete origin/destination pair, so tapping
    // one always restores both fields. This avoids the surprising behaviour where
    // selecting a recent for one field would silently mutate the other.
    func applyRecent(_ recent: RecentSearch) {
        origin = recent.origin
        destination = recent.destination
        suggestions = []
        activeField = nil
        onSuggestionsChanged?()
        onSelectionChanged?()
    }

    func commitSearch() {
        guard let origin, let destination else { return }
        recents.add(origin: origin, destination: destination)
        recentSearches = recents.all()
        onRecentsChanged?()
    }

    func clearRecents() {
        recents.clear()
        recentSearches = []
        onRecentsChanged?()
    }
}
