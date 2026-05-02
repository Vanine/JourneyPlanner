//
//  WatchSessionRelay.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 30.04.2026.
//

import Foundation
import WatchConnectivity

// Watch <-> iPhone bridge — same simple pattern as CalmMed:
//   1. Build a flat [String: Any] context (no JSON Data blobs).
//   2. updateApplicationContext  → latest snapshot, replayed on watch launch.
//   3. transferUserInfo          → guaranteed FIFO fallback when context fails.
//   4. sendMessage               → instant push when watch is reachable.
// On a "requestSync" message from the watch, we re-send the latest context.
final class WatchSessionRelay: NSObject, @unchecked Sendable {
    static let shared = WatchSessionRelay()
    private var session: WCSession?
    private let queue = DispatchQueue(label: "app.journey.planner.watchrelay")
    private var snapshotProvider: (@Sendable () -> (routes: [SharedRoute], departures: [String: [SharedDeparture]])?)?
    private var lastContext: [String: Any]?

    private override init() { super.init() }

    func activate() {
        guard WCSession.isSupported() else { return }
        self.session = WCSession.default
        session?.delegate = self
        if session?.activationState != .activated {
            session?.activate()
        } else {
            flushLatest()
        }
    }

    func setSnapshotProvider(_ provider: @escaping @Sendable () -> (routes: [SharedRoute], departures: [String: [SharedDeparture]])?) {
        queue.sync { snapshotProvider = provider }
        flushLatest()
    }

    func push(routes: [SharedRoute], departuresByRoute: [String: [SharedDeparture]]) {
        let context = Self.makeContext(routes: routes, departures: departuresByRoute)
        queue.sync { lastContext = context }
        deliver(context)
    }

    // MARK: - Context building (raw [String: Any], no JSON blobs)

    private static func makeContext(routes: [SharedRoute], departures: [String: [SharedDeparture]]) -> [String: Any] {
        let routesData: [[String: Any]] = routes.map { r in
            [
                "id": r.id,
                "originID": r.originID,
                "originName": r.originName,
                "destinationID": r.destinationID,
                "destinationName": r.destinationName,
                "savedAt": r.savedAt.timeIntervalSince1970
            ]
        }
        var depData: [String: [[String: Any]]] = [:]
        for (key, deps) in departures {
            depData[key] = deps.map { d in
                [
                    "id": d.id,
                    "routeID": d.routeID,
                    "line": d.line,
                    "transport": d.transport,
                    "platform": d.platform as Any,
                    "destination": d.destination,
                    "departure": d.departure.timeIntervalSince1970,
                    "delayMinutes": d.delayMinutes
                ]
            }
        }
        return [
            "routes": routesData,
            "departures": depData,
            "updatedAt": Date().timeIntervalSince1970,
            "nonce": UUID().uuidString
        ]
    }

    private func currentContext() -> [String: Any]? {
        if let cached: [String: Any] = queue.sync(execute: { lastContext }) {
            return cached
        }
        guard let provider = queue.sync(execute: { snapshotProvider }),
              let snapshot = provider() else { return nil }
        let ctx = Self.makeContext(routes: snapshot.routes, departures: snapshot.departures)
        queue.sync { lastContext = ctx }
        return ctx
    }

    private func deliver(_ payload: [String: Any]) {
        guard WCSession.isSupported() else { return }
        guard session?.activationState == .activated else {
            session?.activate()
            return
        }
        try? session?.updateApplicationContext(payload)
        session?.transferUserInfo(payload)
        session?.sendMessage(payload, replyHandler: nil, errorHandler: nil)
    }

    private func flushLatest() {
        guard let payload = currentContext() else { return }
        deliver(payload)
    }
}

extension WatchSessionRelay: WCSessionDelegate {
    func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        guard activationState == .activated else { return }
        Task { @MainActor in self.flushLatest() }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        self.session?.activate()
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in self.flushLatest() }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in self.flushLatest() }
    }

    func session(_ session: WCSession,
                             didReceiveMessage message: [String : Any],
                             replyHandler: @escaping ([String : Any]) -> Void) {
        let action = (message["action"] as? String) ?? (message["request"] as? String)
        guard action == "requestSync" || action == "snapshot" else {
            replyHandler([:])
            return
        }
        Task { @MainActor in
            if let snapshot = self.currentContext() {
                replyHandler(snapshot)
                self.deliver(snapshot)
            } else {
                replyHandler([:])
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        let action = (message["action"] as? String) ?? (message["request"] as? String)
        if action == "requestSync" || action == "snapshot" {
            Task { @MainActor in self.flushLatest() }
        }
    }
}
