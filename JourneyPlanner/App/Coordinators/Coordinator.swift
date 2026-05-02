//
//  Coordinator.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 17.03.2026.
//

import UIKit

// Coordinator pattern: each flow owns its navigation logic and child coordinators,
// keeping view controllers free of routing concerns.
protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get }
    var childCoordinators: [Coordinator] { get set }
    func start()
}

extension Coordinator {
    func addChild(_ child: Coordinator) {
        childCoordinators.append(child)
    }

    func removeChild(_ child: Coordinator) {
        childCoordinators.removeAll { $0 === child }
    }
}
