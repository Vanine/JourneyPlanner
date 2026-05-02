//
//  ResultsCoordinator.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 26.03.2026.
//

import UIKit

final class ResultsCoordinator: Coordinator {
    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    private let container: DIContainer
    private let origin: Location
    private let destination: Location

    init(
        navigationController: UINavigationController,
        container: DIContainer,
        origin: Location,
        destination: Location
    ) {
        self.navigationController = navigationController
        self.container = container
        self.origin = origin
        self.destination = destination
    }

    func start() {
        let viewModel = ResultsViewModel(
            journeyService: container.journeyService,
            favorites: container.favorites,
            origin: origin,
            destination: destination
        )
        let viewController = ResultsViewController(viewModel: viewModel)
        viewController.onSelectJourney = { [weak self] journey in
            self?.showDetails(for: journey)
        }
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showDetails(for journey: Journey) {
        let viewModel = JourneyDetailsViewModel(journey: journey)
        let viewController = JourneyDetailsViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
