//
//  SearchCoordinator.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 23.03.2026.
//

import UIKit

final class SearchCoordinator: Coordinator {
    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    private let container: DIContainer

    init(navigationController: UINavigationController, container: DIContainer) {
        self.navigationController = navigationController
        self.container = container
    }

    func start() {
        let viewModel = SearchViewModel(
            locationService: container.locationService,
            recents: container.recentSearches
        )
        let viewController = SearchViewController(viewModel: viewModel)
        viewController.onSearch = { [weak self] from, to in
            viewModel.commitSearch()
            self?.showResults(from: from, to: to)
        }
        viewController.onShowFavorites = { [weak self] in
            self?.showFavorites()
        }
        navigationController.setViewControllers([viewController], animated: false)
    }

    private func showResults(from: Location, to: Location) {
        let resultsCoordinator = ResultsCoordinator(
            navigationController: navigationController,
            container: container,
            origin: from,
            destination: to
        )
        addChild(resultsCoordinator)
        resultsCoordinator.start()
    }

    private func showFavorites() {
        let coordinator = FavoritesCoordinator(navigationController: navigationController, container: container)
        addChild(coordinator)
        coordinator.start()
    }
}
