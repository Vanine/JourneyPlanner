//
//  AppCoordinator.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 17.03.2026.
//

import UIKit

final class AppCoordinator: Coordinator {
    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    private let container: DIContainer

    init(navigationController: UINavigationController, container: DIContainer) {
        self.navigationController = navigationController
        self.container = container
    }

    func start() {
        let search = SearchCoordinator(navigationController: navigationController, container: container)
        addChild(search)
        search.start()
    }

    // Entry point for widget / Universal Links. The widget builds URLs of the
    // form `journeyplanner://route?originId=..&originName=..&destId=..&destName=..`
    // — we parse them here and replay the flow as if the user had tapped the
    // route in the favorites tab.
    func handle(deepLink url: URL) {
        guard url.scheme == "journeyplanner" else { return }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host, host == "route" else { return }

        let items = components.queryItems ?? []
        func value(_ name: String) -> String? { items.first(where: { $0.name == name })?.value }

        guard
            let originID = value("originId"),
            let originName = value("originName"),
            let destID = value("destId"),
            let destName = value("destName")
        else { return }

        let origin = Location(id: originID, name: originName, subtitle: "")
        let destination = Location(id: destID, name: destName, subtitle: "")

        navigationController.popToRootViewController(animated: false)
        let resultsCoordinator = ResultsCoordinator(
            navigationController: navigationController,
            container: container,
            origin: origin,
            destination: destination
        )
        addChild(resultsCoordinator)
        resultsCoordinator.start()
    }
}
