//
//  DIContainer.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 17.03.2026.
//

import Foundation

// Lightweight DI container. Protocol-oriented services are resolved here so
// view models stay decoupled from concrete implementations and are testable
// by swapping the conformance (e.g. MockNetworkService).
@MainActor
protocol DIContainer: AnyObject {
    var networkService: NetworkService { get }
    var journeyService: JourneyService { get }
    var locationService: LocationService { get }
    var recentSearches: RecentSearchesRepository { get }
    var favorites: FavoritesRepository { get }
    var sharedRouteStore: SharedRouteStore { get }
    var routeSynchronizer: SharedRouteSynchronizer { get }
}

@MainActor
final class AppDIContainer: DIContainer {
    private let persistence = PersistenceController.shared

    lazy var networkService: NetworkService = MockNetworkService()
    lazy var journeyService: JourneyService = DefaultJourneyService(network: networkService)
    lazy var locationService: LocationService = DefaultLocationService(network: networkService)
    lazy var recentSearches: RecentSearchesRepository = SwiftDataRecentSearchesRepository(context: persistence.context)
    lazy var favorites: FavoritesRepository = SwiftDataFavoritesRepository(context: persistence.context)
    lazy var sharedRouteStore: SharedRouteStore = AppGroupRouteStore()
    lazy var routeSynchronizer: SharedRouteSynchronizer = SharedRouteSynchronizer(
        favorites: favorites,
        journeyService: journeyService,
        store: sharedRouteStore
    )
}
