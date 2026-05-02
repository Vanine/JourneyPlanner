//
//  JourneyService.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 20.03.2026.
//

import Foundation

protocol JourneyService: Sendable {
    func journeys(from: Location, to: Location) async throws -> [Journey]
}

nonisolated struct JourneysResponse: Codable, Sendable {
    let journeys: [Journey]
}

final class DefaultJourneyService: JourneyService {
    private let network: NetworkService

    init(network: NetworkService) { self.network = network }

    func journeys(from: Location, to: Location) async throws -> [Journey] {
        let endpoint = Endpoint(path: "/journeys", query: ["from": from.id, "to": to.id])
        let response: JourneysResponse = try await network.request(endpoint, as: JourneysResponse.self)
        if response.journeys.isEmpty { throw NetworkError.empty }
        return response.journeys
    }
}
