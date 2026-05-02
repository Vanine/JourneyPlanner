//
//  DeparturesViewModel.swift
//  JourneyPlannerWatch
//
//  Created by Vanine Ghazaryan on 29.04.2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class DeparturesViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded([SharedDeparture])
        case empty
        case failed(String)
    }

    let route: SharedRoute
    private(set) var state: LoadState = .idle
    private let store: WatchDataStore

    init(route: SharedRoute, store: WatchDataStore) {
        self.route = route
        self.store = store
    }

    func load() async {
        if case .loading = state { return }
        state = .loading
        let departures = await store.loadDepartures(for: route.id)
        state = departures.isEmpty ? .empty : .loaded(departures)
    }

    func refresh() async {
        let departures = await store.loadDepartures(for: route.id)
        state = departures.isEmpty ? .empty : .loaded(departures)
    }
}
