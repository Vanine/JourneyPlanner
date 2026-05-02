//
//  WatchSessionRelay.swift
//  JourneyPlannerWatch
//
//  Created by Vanine Ghazaryan on 30.04.2026.
//

import Foundation
import WatchConnectivity

extension Notification.Name {
    static let watchSyncDidUpdate = Notification.Name("app.journey.planner.watch.syncDidUpdate")
}

enum WatchLocalStore {
    enum Keys {
        static let routes = "watch.savedRoutes.v1"
        static let departures = "watch.cachedDepartures.v1"
        static let lastUpdated = "watch.lastUpdated.v1"
        static let hasSynced = "watch.hasSynced.v1"
    }
}

final class WatchSessionRelay: NSObject {
    static let shared = WatchSessionRelay()
    private var session: WCSession?

    private let defaults: UserDefaults = .standard
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private override init() { super.init() }

    func activate() {
        guard WCSession.isSupported() else { return }
        session = WCSession.default
        session?.delegate = self
        if session?.activationState != .activated {
            session?.activate()
        } else {
            persistContext(session?.receivedApplicationContext ?? [:])
            requestSyncIfReachable()
        }
    }

    func requestSnapshot() {
        requestSyncIfReachable()
    }

    private func requestSyncIfReachable(attempt: Int = 0) {
        guard session?.activationState == .activated else { return }
        session?.sendMessage(
            ["action": "requestSync"],
            replyHandler: { [weak self] reply in
                guard let self else { return }
                Task { @MainActor in
                    let landed = self.persistContext(reply)
                    if !landed, attempt < 4 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                            self?.requestSyncIfReachable(attempt: attempt + 1)
                        }
                    }
                }
            },
            errorHandler: { [weak self] _ in
                guard attempt < 4 else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                    self?.requestSyncIfReachable(attempt: attempt + 1)
                }
            }
        )
    }

    // Decode the raw [String: Any] payload from the iPhone and write it as
    // JSON into the watch's UserDefaults so LocalWatchDataStore can read it.
    @MainActor @discardableResult
    private func persistContext(_ context: [String: Any]) -> Bool {
        var didChange = false

        if let raw = context["routes"] as? [[String: Any]] {
            let routes = raw.compactMap(Self.decodeRoute)
            if let data = try? encoder.encode(routes) {
                defaults.set(data, forKey: WatchLocalStore.Keys.routes)
                didChange = true
            }
        } else if let data = context["routes"] as? Data {
            // Backwards-compat with older iPhone builds that sent JSON blobs.
            defaults.set(data, forKey: WatchLocalStore.Keys.routes)
            didChange = true
        }

        if let raw = context["departures"] as? [String: [[String: Any]]] {
            var decoded: [String: [SharedDeparture]] = [:]
            for (key, list) in raw {
                decoded[key] = list.compactMap(Self.decodeDeparture)
            }
            if let data = try? encoder.encode(decoded) {
                defaults.set(data, forKey: WatchLocalStore.Keys.departures)
                didChange = true
            }
        } else if let data = context["departures"] as? Data {
            defaults.set(data, forKey: WatchLocalStore.Keys.departures)
            didChange = true
        }

        guard didChange else { return false }
        defaults.set(Date(), forKey: WatchLocalStore.Keys.lastUpdated)
        defaults.set(true, forKey: WatchLocalStore.Keys.hasSynced)
        NotificationCenter.default.post(name: .watchSyncDidUpdate, object: nil)
        return true
    }

    private static func decodeRoute(_ dict: [String: Any]) -> SharedRoute? {
        guard let id = dict["id"] as? String,
              let originID = dict["originID"] as? String,
              let originName = dict["originName"] as? String,
              let destinationID = dict["destinationID"] as? String,
              let destinationName = dict["destinationName"] as? String,
              let savedAt = dict["savedAt"] as? TimeInterval else { return nil }
        return SharedRoute(
            id: id,
            originID: originID,
            originName: originName,
            destinationID: destinationID,
            destinationName: destinationName,
            savedAt: Date(timeIntervalSince1970: savedAt)
        )
    }

    private static func decodeDeparture(_ dict: [String: Any]) -> SharedDeparture? {
        guard let id = dict["id"] as? String,
              let routeID = dict["routeID"] as? String,
              let line = dict["line"] as? String,
              let transport = dict["transport"] as? String,
              let destination = dict["destination"] as? String,
              let departure = dict["departure"] as? TimeInterval,
              let delayMinutes = dict["delayMinutes"] as? Int else { return nil }
        let platform = dict["platform"] as? String
        return SharedDeparture(
            id: id,
            routeID: routeID,
            line: line,
            transport: transport,
            platform: platform,
            destination: destination,
            departure: Date(timeIntervalSince1970: departure),
            delayMinutes: delayMinutes
        )
    }
}

extension WatchSessionRelay: WCSessionDelegate {
    func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        guard activationState == .activated else { return }
        let context = session.receivedApplicationContext
        Task { @MainActor in
            self.persistContext(context)
            self.requestSyncIfReachable()
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            self.persistContext(applicationContext)
        }
    }

    // Real-time push from the iPhone while both apps are foreground.
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            self.persistContext(message)
        }
    }

    // Fallback channel — the iPhone uses transferUserInfo when
    // updateApplicationContext is throttled or fails.
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        Task { @MainActor in
            self.persistContext(userInfo)
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in self.requestSyncIfReachable() }
    }
}
