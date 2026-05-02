//
//  SceneDelegate.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 16.03.2026.
//

import UIKit

// SceneDelegate owns the window and bootstraps the AppCoordinator with the
// shared DI container. It also wires up the deep-link path used by the
// WidgetKit extension (journeyplanner://route?origin=...&destination=...).
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var appCoordinator: AppCoordinator?
    private var favoritesObserver: NSObjectProtocol?
    private var container: DIContainer?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .dark
        window.tintColor = UIColor(red: 0.55, green: 0.75, blue: 1.0, alpha: 1.0)

        configureNavigationBarAppearance()

        let container = AppDIContainer()

        // Wire the relay so it can answer snapshot requests from the watch
        // (lazy, thread-safe — reads straight from the App Group container).
        let store = container.sharedRouteStore
        WatchSessionRelay.shared.setSnapshotProvider { [store] in
            (routes: store.loadRoutes(), departures: store.loadAllDepartures())
        }

        // Activate WCSession early so the watch app can receive the initial
        // application context once the iOS app finishes its first sync.
        WatchSessionRelay.shared.activate()
        let navigationController = UINavigationController()
        navigationController.navigationBar.prefersLargeTitles = true

        let coordinator = AppCoordinator(
            navigationController: navigationController,
            container: container
        )
        coordinator.start()

        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        self.window = window
        self.appCoordinator = coordinator
        self.container = container

        // Observe favorites mutations so we can keep the App Group store
        // in sync with everything the widget and watch app render.
        favoritesObserver = NotificationCenter.default.addObserver(
            forName: .favoritesDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.synchronizeWidgets()
            }
        }

        // Initial sync on launch — push current favorites into the shared
        // container, then refresh cached departures in the background.
        synchronizeWidgets()

        // Honour any deep link the widget tap delivered with launch.
        if let url = connectionOptions.urlContexts.first?.url {
            handle(url: url)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handle(url: url)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        synchronizeWidgets()
    }

    deinit {
        if let favoritesObserver { NotificationCenter.default.removeObserver(favoritesObserver) }
    }

    // MARK: - Deep links

    private func handle(url: URL) {
        appCoordinator?.handle(deepLink: url)
    }

    // MARK: - Widget / Watch sync

    private func synchronizeWidgets() {
        guard let container else { return }
        container.routeSynchronizer.syncRoutes()
        Task.detached { @MainActor [weak self] in
            await self?.container?.routeSynchronizer.refreshDepartures()
        }
    }

    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(red: 0.55, green: 0.75, blue: 1.0, alpha: 1.0)
    }
}
