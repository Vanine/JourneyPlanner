//
//  JourneyPlannerWatchApp.swift
//  JourneyPlannerWatch
//
//  Created by Vanine Ghazaryan on 27.04.2026.
//

import SwiftUI

// Entry point for the watchOS companion app. The watch target reuses the
// shared MVVM + DI architecture: a tiny `WatchDIContainer` resolves the data
// store once and hands it down to view models via `.environment`.
@main
struct JourneyPlannerWatchApp: App {
    private let container = WatchDIContainer()

    init() {
        // Start receiving favorites from the iPhone immediately on launch.
        WatchSessionRelay.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            FavoritesListView()
                .environment(\.watchContainer, container)
        }
    }
}

@MainActor
final class WatchDIContainer {
    let store: WatchDataStore = LocalWatchDataStore()
}

private struct WatchContainerKey: EnvironmentKey {
    static let defaultValue: WatchDIContainer = WatchDIContainer()
}

extension EnvironmentValues {
    var watchContainer: WatchDIContainer {
        get { self[WatchContainerKey.self] }
        set { self[WatchContainerKey.self] = newValue }
    }
}
