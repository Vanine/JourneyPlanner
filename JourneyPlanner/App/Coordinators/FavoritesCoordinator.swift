//
//  FavoritesCoordinator.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 06.04.2026.
//

import UIKit

final class FavoritesCoordinator: Coordinator {
    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    private let container: DIContainer

    init(navigationController: UINavigationController, container: DIContainer) {
        self.navigationController = navigationController
        self.container = container
    }

    func start() {
        let viewModel = FavoritesViewModel(favorites: container.favorites)
        let viewController = FavoritesViewController(viewModel: viewModel)
        viewController.onSelect = { [weak self] item in
            self?.showDetails(for: item)
        }
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showDetails(for item: FavoriteJourney) {
        let viewModel = JourneyDetailsViewModel(journey: item.journey)
        let viewController = JourneyDetailsViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
