//
//  AppDelegate.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 16.03.2026.
//

import UIKit

// Entry point. Scene-based lifecycle (iOS 13+). The Info.plist scene manifest
// is auto-generated and points to SceneDelegate via the build setting
// INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES.
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}
