//
//  FavoritesViewModel.swift
//  JourneyPlannerWatch
//
//  Created by Vanine Ghazaryan on 28.04.2026.
//

import Foundation
import Observation

// MVVM on the watch follows the same shape as the iOS app: an @Observable
// view model owns loading state, talks to a protocol-typed data store, and
// surfaces a small public API for SwiftUI to bind to.
@MainActor
@Observable
final class FavoritesViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded([SharedRoute])
        case empty
        case failed(String)
    }

    private(set) var state: LoadState = .idle
    private let store: WatchDataStore

    init(store: WatchDataStore, defaults: UserDefaults = .standard) {
        self.store = store
    }

    func load() async {
        if case .loading = state { return }
        // Only show the spinner on the very first load. Subsequent reloads
        // (triggered by WCSession pushes / pull-to-refresh) keep the current
        // list visible to avoid UI flicker.
        if case .idle = state { state = .loading }
        let routes = await store.loadRoutes()
        state = routes.isEmpty ? .empty : .loaded(routes)
    }

    func refresh() async {
        let routes = await store.loadRoutes()
        state = routes.isEmpty ? .empty : .loaded(routes)
    }
}
